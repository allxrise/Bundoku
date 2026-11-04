#!/usr/bin/env python3
"""Load Bundoku device telemetry dumps into a BigQuery table.

Reads one or more local JSONL files written by the Telemetry autoload
(user://telemetry/events-*.jsonl), derives the ``event_date`` partition column
from ``event_ts_us`` (UTC), writes a gzipped newline-delimited JSON file and
hands it to ``bq load``.

Examples:
    python3 tools/bq_load.py --project my-project events-20261104.jsonl
    python3 tools/bq_load.py --project my-project --dry-run dumps/*.jsonl
    python3 tools/bq_load.py --project my-project --dataset bundoku \
        --table telemetry_events --keep-temp events-20261104.jsonl

Only the Python standard library is used.
"""

from __future__ import annotations

import argparse
import datetime as dt
import gzip
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SCHEMA = REPO_ROOT / "assets" / "analytics" / "bigquery_schema.json"
DEFAULT_DATASET = "bundoku"
DEFAULT_TABLE = "telemetry_events"

EXIT_USAGE = 2
EXIT_BAD_DATA = 3
EXIT_LOAD_FAILED = 4


class InputError(Exception):
    """A dump file is missing or contains an unusable row."""


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Load Bundoku telemetry JSONL dumps into BigQuery.",
    )
    parser.add_argument(
        "--project",
        default=os.environ.get("GOOGLE_CLOUD_PROJECT", ""),
        help="Google Cloud project id (default: $GOOGLE_CLOUD_PROJECT).",
    )
    parser.add_argument("--dataset", default=DEFAULT_DATASET, help="BigQuery dataset (default: bundoku).")
    parser.add_argument("--table", default=DEFAULT_TABLE, help="BigQuery table (default: telemetry_events).")
    parser.add_argument(
        "--schema",
        default=str(DEFAULT_SCHEMA),
        help="BigQuery JSON schema path (default: assets/analytics/bigquery_schema.json).",
    )
    parser.add_argument("--dry-run", action="store_true", help="Validate inputs and print the bq command only.")
    parser.add_argument("--keep-temp", action="store_true", help="Keep the generated gzipped NDJSON file.")
    parser.add_argument("files", nargs="+", metavar="FILE", help="Device JSONL dump(s) to load.")
    return parser.parse_args(argv)


def event_date_for(row: dict, source: str, lineno: int) -> str:
    """Return the UTC date string for a row's event_ts_us."""
    ts = row.get("event_ts_us")
    if isinstance(ts, bool) or not isinstance(ts, int):
        raise InputError(f"{source}:{lineno}: event_ts_us must be an integer, got {ts!r}")
    try:
        stamp = dt.datetime.fromtimestamp(ts / 1_000_000, tz=dt.timezone.utc)
    except (OverflowError, OSError, ValueError) as exc:
        raise InputError(f"{source}:{lineno}: event_ts_us {ts!r} is out of range ({exc})") from exc
    return stamp.strftime("%Y-%m-%d")


def write_rows(files: list[str], out_path: Path | None) -> int:
    """Validate rows and, when out_path is given, write them as gzipped NDJSON.

    Derives ``event_date`` for every row. Returns the row count.
    """
    count = 0
    out = gzip.open(out_path, "wt", encoding="utf-8", newline="\n") if out_path is not None else None
    try:
        for name in files:
            path = Path(name)
            if not path.is_file():
                raise InputError(f"{name}: no such file")
            with path.open("r", encoding="utf-8") as src:
                for lineno, line in enumerate(src, start=1):
                    if not line.strip():
                        continue
                    try:
                        row = json.loads(line)
                    except json.JSONDecodeError as exc:
                        raise InputError(f"{name}:{lineno}: invalid JSON ({exc.msg} at column {exc.colno})") from exc
                    if not isinstance(row, dict):
                        raise InputError(f"{name}:{lineno}: row must be a JSON object")
                    row["event_date"] = event_date_for(row, name, lineno)
                    if out is not None:
                        out.write(json.dumps(row, separators=(",", ":"), ensure_ascii=False))
                        out.write("\n")
                    count += 1
    finally:
        if out is not None:
            out.close()
    return count


def build_command(args: argparse.Namespace, table_ref: str, data_path: str, schema: Path) -> list[str]:
    return [
        "bq",
        "load",
        "--source_format=NEWLINE_DELIMITED_JSON",
        f"--schema={schema}",
        "--time_partitioning_field=event_date",
        "--clustering_fields=event_name",
        table_ref,
        data_path,
    ]


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    if not args.project:
        print("error: --project is required (or set GOOGLE_CLOUD_PROJECT)", file=sys.stderr)
        return EXIT_USAGE

    schema = Path(args.schema).expanduser().resolve()
    if not schema.is_file():
        print(f"error: schema not found: {schema}", file=sys.stderr)
        return EXIT_USAGE

    table_ref = f"{args.project}:{args.dataset}.{args.table}"
    bq_path = shutil.which("bq")
    if bq_path is None and not args.dry_run:
        print(
            "error: `bq` was not found on PATH. Install the Google Cloud CLI "
            "(https://cloud.google.com/sdk/docs/install) and run `gcloud auth login`.",
            file=sys.stderr,
        )
        return EXIT_USAGE

    tmp_path = None
    try:
        if args.dry_run:
            print(f"# validating {len(args.files)} file(s)", file=sys.stderr)
            rows = write_rows(args.files, None)
            print(f"# {rows} row(s) valid", file=sys.stderr)
            cmd = build_command(args, table_ref, "<tmpfile>.jsonl.gz", schema)
            print(shlex.join(cmd))
            return 0

        fd, tmp_name = tempfile.mkstemp(prefix="bundoku-telemetry-", suffix=".jsonl.gz")
        os.close(fd)
        tmp_path = Path(tmp_name)
        rows = write_rows(args.files, tmp_path)

        cmd = build_command(args, table_ref, str(tmp_path), schema)
        print(f"# loading {rows} row(s) into {table_ref}", file=sys.stderr)
        result = subprocess.run(cmd, check=False)
        if result.returncode != 0:
            print(f"error: bq load failed with exit code {result.returncode}", file=sys.stderr)
            if args.keep_temp:
                print(f"# kept {tmp_path}", file=sys.stderr)
            return EXIT_LOAD_FAILED
        print(f"# loaded {rows} row(s) into {table_ref}", file=sys.stderr)
        return 0
    except InputError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return EXIT_BAD_DATA
    finally:
        if tmp_path is not None and tmp_path.exists() and not args.keep_temp:
            tmp_path.unlink()


if __name__ == "__main__":
    sys.exit(main())
