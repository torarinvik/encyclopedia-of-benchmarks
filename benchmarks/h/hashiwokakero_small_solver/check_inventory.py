"""Static inventory checker; intentionally not run during source-only work."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/h/hashiwokakero_small_solver"
ALGORITHM = "hashiwokakero_small_solver"
LANGUAGE_PATHS = {
    "c": "c/h/hashiwokakero_small_solver.c",
    "c3": "c3/h/hashiwokakero_small_solver.c3",
    "cpp": "cpp/h/hashiwokakero_small_solver.cpp",
    "elisa": "elisa/h/hashiwokakero_small_solver.elisa",
    "mojo": "mojo/h/hashiwokakero_small_solver.mojo",
    "nim": "nim/h/hashiwokakero_small_solver.nim",
    "odin": "odin/h/hashiwokakero_small_solver.odin",
    "rust": "rust/h/hashiwokakero_small_solver.rs",
    "v": "v/h/hashiwokakero_small_solver.v",
    "zig": "zig/h/hashiwokakero_small_solver.zig",
}
PACKAGE_FILES = {
    "README.md",
    "RIGHTS.md",
    "RESERVATION.md",
    "INVENTORY.md",
    "INVENTORY.json",
    "workload.json",
    "primary_oracle.py",
    "independent_oracle.py",
    "verify_workload.py",
    "check_inventory.py",
}
CASE_IDS = {
    "two-islands-double-bridge",
    "two-islands-single-bridge",
    "shared-endpoint-chain",
    "lexicographic-tie-square",
    "maximum-edge-count-2x3",
    "disconnected-degree-satisfied",
    "interior-crossing-required",
    "valid-but-degree-unsatisfiable",
    "maximum-length-no-visible-bridges",
    "duplicate-coordinate",
    "coordinate-out-of-range",
    "zero-demand",
    "one-island-out-of-range",
    "trailing-word",
    "null-input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("languages") != LANGUAGE_PATHS
            or set(inventory.get("package_files", [])) != PACKAGE_FILES):
        issues.append("inventory identity, ABI, language paths, or package file set differs")
    for filename in PACKAGE_FILES:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    for language, relative_path in LANGUAGE_PATHS.items():
        path = ROOT / relative_path
        if not path.is_file():
            issues.append(f"missing {language} source: {relative_path}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"symbol marker missing in {relative_path}")

    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_length") != 19
            or workload.get("input", {}).get("maximum_parseable_length") != 20
            or workload.get("method", {}).get("maximum_candidate_edges") != 7
            or workload.get("method", {}).get("maximum_independent_vectors") != 2187
            or inventory.get("maximum_valid_input_words") != 19
            or inventory.get("maximum_parseable_input_words") != 20):
        issues.append("workload or inventory contract bounds differ")

    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed case set")
    for case in cases:
        if not isinstance(case, dict):
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        if (not isinstance(values, list) or type(length) is not int
                or length > 20 or (not case.get("input_is_null", False) and length != len(values))
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(case.get("expected_result")) is not int):
            issues.append(f"invalid scalar fixture framing: {case.get('id')}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
