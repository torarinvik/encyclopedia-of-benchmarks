"""Static inventory checker; it does not compile or execute native sources."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/r/round_robin_tournament_schedule.c",
    "c3": "c3/r/round_robin_tournament_schedule.c3",
    "cpp": "cpp/r/round_robin_tournament_schedule.cpp",
    "elisa": "elisa/r/round_robin_tournament_schedule.elisa",
    "mojo": "mojo/r/round_robin_tournament_schedule.mojo",
    "nim": "nim/r/round_robin_tournament_schedule.nim",
    "odin": "odin/r/round_robin_tournament_schedule.odin",
    "rust": "rust/r/round_robin_tournament_schedule.rs",
    "v": "v/r/round_robin_tournament_schedule.v",
    "zig": "zig/r/round_robin_tournament_schedule.zig",
}


def static_issues() -> list[str]:
    """Return metadata or file-presence issues without running project tools."""
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read inventory: {error}"]
    errors: list[str] = []
    if metadata.get("algorithm") != "round_robin_tournament_schedule":
        errors.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        errors.append("language source map differs")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            errors.append(f"missing language source {relative}")
    package_files = metadata.get("package_files")
    if not isinstance(package_files, list):
        errors.append("package_files must be a list")
    else:
        for relative in package_files:
            if not isinstance(relative, str) or not (PACKAGE / relative).is_file():
                errors.append(f"missing package artifact {relative}")
    if metadata.get("bounds") != {
        "minimum_teams": 2,
        "maximum_teams": 8,
        "maximum_valid_input_words": 1,
        "maximum_parseable_input_words": 2,
        "maximum_output_bytes": 58,
        "workspace_bytes": 128,
    }:
        errors.append("inventory bounds differ from the package contract")
    return errors


def check_inventory() -> list[str]:
    """Common suite import alias for the static inventory review."""
    return static_issues()


if __name__ == "__main__":
    issues = static_issues()
    if issues:
        raise SystemExit("\n".join(issues))
