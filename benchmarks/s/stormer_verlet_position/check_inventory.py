"""Static port-inventory check; intentionally not run during source-only work."""

from __future__ import annotations

import re
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
EXPECTED_LANGUAGES = {"C", "C3", "C++", "Elisa", "Mojo", "Nim", "Odin", "Rust", "V", "Zig"}
PORT_PREFIX = {
    "C": "c",
    "C3": "c3",
    "C++": "cpp",
    "Elisa": "elisa",
    "Mojo": "mojo",
    "Nim": "nim",
    "Odin": "odin",
    "Rust": "rust",
    "V": "v",
    "Zig": "zig",
}


def validate_inventory() -> None:
    text = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    rows = re.findall(r"^\| (C3|C\+\+|C|Elisa|Mojo|Nim|Odin|Rust|V|Zig) \| `([^`]+)` \| `([^`]+)` \|$", text, re.MULTILINE)
    found = {language for language, _, _ in rows}
    if found != EXPECTED_LANGUAGES:
        raise ValueError(f"inventory languages differ: {found ^ EXPECTED_LANGUAGES}")
    for language, relative_path, symbol in rows:
        source = REPOSITORY / relative_path
        if not source.is_file():
            raise ValueError(f"missing source: {relative_path}")
        if symbol not in source.read_text(encoding="utf-8"):
            raise ValueError(f"missing exported symbol {symbol} in {relative_path}")
        expected_path = REPOSITORY / PORT_PREFIX[language] / "s" / "stormer_verlet_position"
        if source.with_suffix("") != expected_path:
            raise ValueError(f"unexpected inventory location: {relative_path}")


if __name__ == "__main__":
    validate_inventory()
