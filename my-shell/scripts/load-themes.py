#!/usr/bin/env python3

import json
import pathlib
import sys


def main() -> int:
    theme_dir = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path("themes")
    themes = []

    for path in sorted(theme_dir.glob("*.json")):
        with path.open("r", encoding="utf-8") as handle:
            themes.append(json.load(handle))

    json.dump(themes, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
