"""Static package inventory checker; it never compiles or runs language ports."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "landau_vishkin_k_difference_pattern_matching"
LANGUAGE_PATHS = {
    "c": "c/l/landau_vishkin_k_difference_pattern_matching.c",
    "c3": "c3/l/landau_vishkin_k_difference_pattern_matching.c3",
    "cpp": "cpp/l/landau_vishkin_k_difference_pattern_matching.cpp",
    "elisa": "elisa/l/landau_vishkin_k_difference_pattern_matching.elisa",
    "mojo": "mojo/l/landau_vishkin_k_difference_pattern_matching.mojo",
    "nim": "nim/l/landau_vishkin_k_difference_pattern_matching.nim",
    "odin": "odin/l/landau_vishkin_k_difference_pattern_matching.odin",
    "rust": "rust/l/landau_vishkin_k_difference_pattern_matching.rs",
    "v": "v/l/landau_vishkin_k_difference_pattern_matching.v",
    "zig": "zig/l/landau_vishkin_k_difference_pattern_matching.zig",
}


def static_issues() -> list[str]:
    """Return absent or inconsistent source/package metadata without execution."""
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    issues: list[str] = []
    if metadata.get("algorithm") != ALGORITHM:
        issues.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if metadata.get("function_symbol") != ALGORITHM:
        issues.append("inventory function symbol differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        issues.append("language source map differs")
    for relative in LANGUAGE_PATHS.values():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language source {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing in {relative}")
    for relative in metadata.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package file {relative}")
    if workload.get("algorithm") != ALGORITHM:
        issues.append("workload algorithm differs")
    if workload.get("function_symbol") != ALGORITHM:
        issues.append("workload function symbol differs")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI differs")
    input_contract = workload.get("input", {})
    output_contract = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if input_contract.get("maximum_valid_input_length") != 51:
        issues.append("valid input bound differs")
    if input_contract.get("maximum_parseable_input_length") != 52:
        issues.append("parseable input bound differs")
    if output_contract.get("maximum_bytes") != 32:
        issues.append("output bound differs")
    if workspace.get("bytes") != 4096:
        issues.append("workspace bound differs")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
