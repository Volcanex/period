"""Build the app's Phosphor icon font from the upstream family.

The client bundles only the glyphs it actually draws. Shipping the whole
Phosphor family, or depending on `phosphor_flutter`, costs megabytes: that
package exposes icons as instance getters rather than `const IconData`, so
Flutter's `--tree-shake-icons` pass cannot prove which code points are live and
gives up, shipping all six weights.

Subsetting sidesteps that. The output is a handful of glyphs, referenced from
`app/lib/theme/icons.dart` as plain `const IconData`.

Requires `pyftsubset` (fontTools). Run from the repo root when the icon list
below changes:

    python3 scripts/subset_icon_font.py

Source font: https://github.com/phosphor-icons/web (MIT), regular weight.
Code points come from that repo's `src/regular/style.css`.
"""

import subprocess
import sys
from pathlib import Path
from urllib.request import urlopen

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "app" / "assets" / "fonts" / "PhosphorSubset.ttf"
SOURCE_URL = (
    "https://raw.githubusercontent.com/phosphor-icons/web/master/"
    "src/regular/Phosphor.ttf"
)

# name -> code point. Keep in sync with app/lib/theme/icons.dart.
ICONS = {
    "lock-simple": 0xE308,
    "device-mobile": 0xE1E0,
    "user-circle": 0xE4C4,
    "code": 0xE1BC,
    "caret-left": 0xE138,
    "caret-right": 0xE13A,
    "calendar-blank": 0xE10A,
    "minus": 0xE32A,
    "plus": 0xE3D4,
    "circle": 0xE18A,
    "chart-line": 0xE154,
    "list-checks": 0xEADC,
}


def main():
    src = REPO / "build" / "Phosphor-Regular.ttf"
    if not src.exists():
        src.parent.mkdir(parents=True, exist_ok=True)
        print(f"downloading {SOURCE_URL}")
        src.write_bytes(urlopen(SOURCE_URL).read())

    OUT.parent.mkdir(parents=True, exist_ok=True)
    unicodes = ",".join(f"U+{cp:04X}" for cp in sorted(ICONS.values()))
    subprocess.run(
        [
            "pyftsubset",
            str(src),
            f"--unicodes={unicodes}",
            f"--output-file={OUT}",
            "--no-hinting",
            "--desubroutinize",
            "--drop-tables+=DSIG",
            "--name-IDs=*",
        ],
        check=True,
    )
    print(
        f"wrote {len(ICONS)} glyphs -> {OUT.relative_to(REPO)} "
        f"({OUT.stat().st_size:,} bytes, from {src.stat().st_size:,})"
    )


if __name__ == "__main__":
    sys.exit(main())
