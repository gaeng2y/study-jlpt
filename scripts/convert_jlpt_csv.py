#!/usr/bin/env python3
import csv
import os
import re
import sys
from pathlib import Path

LEVEL_RE = re.compile(r"n([1-5])\.csv$", re.IGNORECASE)


def level_from_filename(path: Path) -> str:
    m = LEVEL_RE.search(path.name)
    if not m:
        raise ValueError(f"Cannot infer JLPT level from filename: {path}")
    return f"N{m.group(1)}"


def clean(value: str) -> str:
    return (value or "").strip()


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print("Usage: convert_jlpt_csv.py <output.csv> <input1.csv> [<input2.csv> ...]", file=sys.stderr)
        return 1

    output = Path(argv[1]).expanduser().resolve()
    inputs = [Path(p).expanduser().resolve() for p in argv[2:]]

    output.parent.mkdir(parents=True, exist_ok=True)

    seen = set()
    rows = []
    skipped = 0

    for input_path in inputs:
      level = level_from_filename(input_path)
      with input_path.open("r", encoding="utf-8-sig", newline="") as f:
          reader = csv.DictReader(f)
          for src in reader:
              jp = clean(src.get("expression", ""))
              reading = clean(src.get("reading", ""))
              meaning = clean(src.get("meaning", ""))

              if not jp or not meaning:
                  skipped += 1
                  continue

              key = (level, jp, reading, meaning)
              if key in seen:
                  continue
              seen.add(key)

              rows.append({
                  "jlpt_level": level,
                  "jp": jp,
                  "reading": reading,
                  "meaning_ko": meaning,
                  "kind": "vocab",
                  "is_active": "true",
              })

    rows.sort(key=lambda r: (r["jlpt_level"], r["jp"], r["reading"]))

    with output.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["jlpt_level", "jp", "reading", "meaning_ko", "kind", "is_active"],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {output}")
    print(f"Skipped {skipped} malformed rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
