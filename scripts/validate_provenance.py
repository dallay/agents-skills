#!/usr/bin/env python3
"""Validate SHA-256 entries recorded in PROVENANCE.md."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path


HASH_ENTRY = re.compile(r"^- `(?P<path>[^`]+)`: `(?P<digest>[0-9a-f]{64})`$")


def parse_hash_entries(provenance_path: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for line in provenance_path.read_text().splitlines():
        match = HASH_ENTRY.fullmatch(line)
        if match:
            relative_path = match.group("path")
            if relative_path in entries:
                raise ValueError(f"duplicate provenance hash entry: {relative_path}")
            entries[relative_path] = match.group("digest")

    if not entries:
        raise ValueError(f"no materialized file hashes found in {provenance_path}")
    return entries


def validate(root: Path) -> list[str]:
    provenance_path = root / "PROVENANCE.md"
    entries = parse_hash_entries(provenance_path)
    failures: list[str] = []

    for relative_path, recorded_digest in entries.items():
        if Path(relative_path).is_absolute() or ".." in Path(relative_path).parts:
            failures.append(f"{relative_path}: invalid relative path")
            continue

        materialized_path = root / "skills" / relative_path
        if not materialized_path.is_file():
            failures.append(f"{relative_path}: materialized file is missing")
            continue

        actual_digest = hashlib.sha256(materialized_path.read_bytes()).hexdigest()
        if actual_digest != recorded_digest:
            failures.append(
                f"{relative_path}: recorded {recorded_digest}, current {actual_digest}"
            )

    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="agents-skills repository root (default: inferred from this script)",
    )
    args = parser.parse_args()
    root = args.root.resolve()

    try:
        failures = validate(root)
    except (OSError, ValueError) as error:
        print(f"[FAIL] provenance validation error: {error}", file=sys.stderr)
        return 1

    if failures:
        for failure in failures:
            print(f"[FAIL] {failure}", file=sys.stderr)
        return 1

    print(f"[OK] validated materialized hashes in {root / 'PROVENANCE.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
