"""Static package inventory checker; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/a/asteroid_collision_stack.c",
    "c3": "c3/a/asteroid_collision_stack.c3",
    "cpp": "cpp/a/asteroid_collision_stack.cpp",
    "elisa": "elisa/a/asteroid_collision_stack.elisa",
    "mojo": "mojo/a/asteroid_collision_stack.mojo",
    "nim": "nim/a/asteroid_collision_stack.nim",
    "odin": "odin/a/asteroid_collision_stack.odin",
    "rust": "rust/a/asteroid_collision_stack.rs",
    "v": "v/a/asteroid_collision_stack.v",
    "zig": "zig/a/asteroid_collision_stack.zig",
}


def static_issues() -> list[str]:
    """List missing or mismatched artifacts without compiling source files."""
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read inventory: {error}"]
    errors: list[str] = []
    if metadata.get("algorithm") != "asteroid_collision_stack":
        errors.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        errors.append("language source map differs")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            errors.append(f"missing language source {relative}")
    files = metadata.get("package_files")
    if not isinstance(files, list):
        errors.append("package_files must be a list")
    else:
        for relative in files:
            if not isinstance(relative, str) or not (PACKAGE / relative).is_file():
                errors.append(f"missing package file {relative}")
    bounds = metadata.get("bounds", {})
    if bounds != {
        "maximum_valid_input_words": 65,
        "maximum_parseable_input_words": 66,
        "maximum_output_bytes": 65,
        "workspace_bytes": 512,
    }:
        errors.append("inventory bounds differ from the package contract")
    return errors


def check_inventory() -> list[str]:
    """Standard suite import alias for ``static_issues``."""
    return static_issues()


if __name__ == "__main__":
    issues = static_issues()
    if issues:
        raise SystemExit("\n".join(issues))
