#!/usr/bin/env python3
"""Append one dated maintenance entry, once per Pakistan calendar day."""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

TIME_ZONE = ZoneInfo("Asia/Karachi")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path)
    args = parser.parse_args()

    now = datetime.now(TIME_ZONE)
    date_text = now.date().isoformat()
    path = args.path
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    marker = f"## {date_text}"

    print(f"date={date_text}")
    if marker in existing.splitlines():
        print(f"updated=false")
        with open(os.environ.get("GITHUB_OUTPUT", os.devnull), "a", encoding="utf-8") as output:
            output.write(f"updated=false\ndate={date_text}\n")
        return 0

    entry = (
        f"{marker}\n\n"
        "- Daily automated repository maintenance completed.\n"
        f"- Timestamp: {now.isoformat(timespec='seconds')}\n"
        "- Status: Successful\n"
    )
    separator = "\n" if existing and not existing.endswith("\n") else ""
    path.write_text(existing + separator + entry, encoding="utf-8")

    with open(os.environ.get("GITHUB_OUTPUT", os.devnull), "a", encoding="utf-8") as output:
        output.write(f"updated=true\ndate={date_text}\n")
    print("updated=true")
    return 0


if __name__ == "__main__":
    sys.exit(main())
