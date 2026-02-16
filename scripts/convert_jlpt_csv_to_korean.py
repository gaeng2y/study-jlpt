#!/usr/bin/env python3
import csv
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

LEVEL_RE = re.compile(r"n([1-5])\.csv$", re.IGNORECASE)
API_URL = "https://translate.googleapis.com/translate_a/single"


def level_from_filename(path: Path) -> str:
    m = LEVEL_RE.search(path.name)
    if not m:
        raise ValueError(f"Cannot infer JLPT level from filename: {path}")
    return f"N{m.group(1)}"


def clean(value: str) -> str:
    return (value or "").strip()


def translate_text(text: str, retries: int = 4, timeout: int = 12) -> str:
    if not text:
        return ""
    params = {
        "client": "gtx",
        "sl": "en",
        "tl": "ko",
        "dt": "t",
        "q": text,
    }
    url = f"{API_URL}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0",
            "Accept": "application/json,text/plain,*/*",
        },
    )

    for i in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                # Typical shape: [[[translated, original, ...], ...], ...]
                return "".join(part[0] for part in data[0] if part and part[0]).strip()
        except Exception:
            if i == retries - 1:
                raise
            time.sleep(0.8 * (i + 1))
    return text


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(
            "Usage: convert_jlpt_csv_to_korean.py <output.csv> <input1.csv> [<input2.csv> ...]",
            file=sys.stderr,
        )
        return 1

    output = Path(argv[1]).expanduser().resolve()
    inputs = [Path(p).expanduser().resolve() for p in argv[2:]]
    output.parent.mkdir(parents=True, exist_ok=True)

    rows = []
    seen = set()
    skipped = 0
    meanings = set()

    for input_path in inputs:
        level = level_from_filename(input_path)
        with input_path.open("r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            for src in reader:
                jp = clean(src.get("expression", ""))
                reading = clean(src.get("reading", ""))
                meaning_en = clean(src.get("meaning", ""))
                if not jp or not meaning_en:
                    skipped += 1
                    continue

                key = (level, jp, reading, meaning_en)
                if key in seen:
                    continue
                seen.add(key)
                meanings.add(meaning_en)
                rows.append(
                    {
                        "jlpt_level": level,
                        "jp": jp,
                        "reading": reading,
                        "meaning_en": meaning_en,
                    }
                )

    max_workers = 3
    print(
        f"Loaded {len(rows)} rows, translating {len(meanings)} unique meanings with workers={max_workers}...",
        flush=True,
    )
    ko_map: dict[str, str] = {}

    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        future_map = {pool.submit(translate_text, text): text for text in meanings}
        done = 0
        total = len(future_map)
        for fut in as_completed(future_map):
            src = future_map[fut]
            try:
                ko_map[src] = fut.result()
            except Exception:
                ko_map[src] = src
            done += 1
            if done % 250 == 0 or done == total:
                print(f"Translated {done}/{total}", flush=True)

    out_rows = []
    for r in rows:
        out_rows.append(
            {
                "jlpt_level": r["jlpt_level"],
                "jp": r["jp"],
                "reading": r["reading"],
                "meaning_ko": ko_map.get(r["meaning_en"], r["meaning_en"]),
                "kind": "vocab",
                "is_active": "true",
            }
        )

    out_rows.sort(key=lambda x: (x["jlpt_level"], x["jp"], x["reading"], x["meaning_ko"]))

    with output.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["jlpt_level", "jp", "reading", "meaning_ko", "kind", "is_active"],
        )
        writer.writeheader()
        writer.writerows(out_rows)

    print(f"Wrote {len(out_rows)} rows to {output}", flush=True)
    print(f"Skipped {skipped} malformed rows", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
