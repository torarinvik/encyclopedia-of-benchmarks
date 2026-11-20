"""Static inventory review; this module does not invoke native tooling."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/s/sierpinski_curve_trace.c",
    "c3": "c3/s/sierpinski_curve_trace.c3",
    "cpp": "cpp/s/sierpinski_curve_trace.cpp",
    "elisa": "elisa/s/sierpinski_curve_trace.elisa",
    "mojo": "mojo/s/sierpinski_curve_trace.mojo",
    "nim": "nim/s/sierpinski_curve_trace.nim",
    "odin": "odin/s/sierpinski_curve_trace.odin",
    "rust": "rust/s/sierpinski_curve_trace.rs",
    "v": "v/s/sierpinski_curve_trace.v",
    "zig": "zig/s/sierpinski_curve_trace.zig",
}


def static_issues() -> list[str]:
    """Return missing-file or metadata discrepancies from static reads only."""
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read inventory: {error}"]
    errors: list[str] = []
    if metadata.get("algorithm") != "sierpinski_curve_trace":
        errors.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        errors.append("language source map differs")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            errors.append(f"missing language source {relative}")
    artifacts = metadata.get("package_files")
    if not isinstance(artifacts, list):
        errors.append("package_files must be a list")
    else:
        for relative in artifacts:
            if not isinstance(relative, str) or not (PACKAGE / relative).is_file():
                errors.append(f"missing package artifact {relative}")
    expected_bounds = {
        "minimum_order": 0,
        "maximum_order": 2,
        "maximum_valid_input_words": 1,
        "maximum_parseable_input_words": 2,
        "maximum_output_bytes": 64,
        "workspace_bytes": 256,
    }
    if metadata.get("bounds") != expected_bounds:
        errors.append("inventory bounds differ from package contract")
    return errors


def check_inventory() -> list[str]:
    """Standard suite-import alias for the non-executing inventory review."""
    return static_issues()


if __name__ == "__main__":
    issues = static_issues()
    if issues:
        raise SystemExit("\n".join(issues))
