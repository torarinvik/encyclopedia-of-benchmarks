"""Static package-path and metadata inventory check; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/p/punycode_codepoint_sequence_encode.c",
    "c3": "c3/p/punycode_codepoint_sequence_encode.c3",
    "cpp": "cpp/p/punycode_codepoint_sequence_encode.cpp",
    "elisa": "elisa/p/punycode_codepoint_sequence_encode.elisa",
    "mojo": "mojo/p/punycode_codepoint_sequence_encode.mojo",
    "nim": "nim/p/punycode_codepoint_sequence_encode.nim",
    "odin": "odin/p/punycode_codepoint_sequence_encode.odin",
    "rust": "rust/p/punycode_codepoint_sequence_encode.rs",
    "v": "v/punycode_codepoint_sequence_encode.v",
    "zig": "zig/p/punycode_codepoint_sequence_encode.zig",
}


def static_issues() -> list[str]:
    metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if metadata.get("algorithm") != "punycode_codepoint_sequence_encode":
        issues.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        issues.append("inventory language map differs")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            issues.append(f"missing language source: {relative}")
    for relative in metadata.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    return issues
