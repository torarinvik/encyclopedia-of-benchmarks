"""Non-executing source-path, metadata, and workload framing audit."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/l/lanczos_symmetric_tridiagonalization.c",
    "c3": ROOT / "c3/l/lanczos_symmetric_tridiagonalization.c3",
    "cpp": ROOT / "cpp/l/lanczos_symmetric_tridiagonalization.cpp",
    "elisa": ROOT / "elisa/l/lanczos_symmetric_tridiagonalization.elisa",
    "mojo": ROOT / "mojo/l/lanczos_symmetric_tridiagonalization.mojo",
    "nim": ROOT / "nim/l/lanczos_symmetric_tridiagonalization.nim",
    "odin": ROOT / "odin/l/lanczos_symmetric_tridiagonalization.odin",
    "rust": ROOT / "rust/l/lanczos_symmetric_tridiagonalization.rs",
    "v": ROOT / "v/l/lanczos_symmetric_tridiagonalization.v",
    "zig": ROOT / "zig/l/lanczos_symmetric_tridiagonalization.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    artifacts = ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
                 "workload.json", "primary_oracle.py", "independent_oracle.py",
                 "verify_workload.py", "check_inventory.py", "__init__.py")
    for artifact in artifacts:
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing artifact {artifact}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "lanczos_symmetric_tridiagonalization" not in source:
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
        if "9.094947017729282e-13" not in source:
            issues.append(f"missing the binary64 2^-40 breakdown guard in {path.relative_to(ROOT)}")
        if language == "elisa" and ("view[f64]" not in source or "UnsafePointer" in source or "*f64" in source):
            issues.append("Elisa must use borrowed ABI references and bounded views")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid metadata JSON: {error}"]
    paths = {path.relative_to(ROOT).as_posix() for path in SOURCES.values()}
    if inventory.get("algorithm") != "lanczos_symmetric_tridiagonalization" or set(inventory.get("native_paths", [])) != paths:
        issues.append("inventory identity/native paths differ")
    if (inventory.get("contract", {}).get("breakdown_threshold") != "2^-40"
            or inventory.get("contract", {}).get("exact_nonzero_beta_lower_bound") != "1/256"):
        issues.append("inventory breakdown contract differs")
    if (workload.get("abi") != "float64_slice_io"
            or workload.get("input", {}).get("maximum_valid_input_length") != 18
            or workload.get("input", {}).get("maximum_parseable_input_length") != 19
            or workload.get("output", {}).get("maximum_elements") != 8
            or workload.get("contract", {}).get("breakdown_threshold") != "2^-40"
            or workload.get("contract", {}).get("exact_nonzero_beta_lower_bound", "").split(";")[0] != "1/256"
            or workload.get("output", {}).get("breakdown_threshold") != "2^-40"
            or workload.get("workspace", {}).get("elements") != 8):
        issues.append("workload bounds differ from the package contract")
    cases = workload.get("cases", []) + workload.get("abi_cases", [])
    ids: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("non-object fixture")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in ids:
            issues.append(f"missing or duplicate fixture ID {case_id!r}")
        else:
            ids.add(case_id)
        values, length = case.get("input_values"), case.get("input_length")
        if (not isinstance(values, list) or type(length) is not int
                or (not case.get("input_is_null", False) and length != len(values))
                or length > 19):
            issues.append(f"invalid input framing for {case_id}")
            continue
        result, output = case.get("expected_result"), case.get("expected_output")
        if (type(result) is not int or not isinstance(output, list)
                or (result >= 0 and (len(output) != result or result > 8))
                or (result < 0 and output)):
            issues.append(f"invalid expected output framing for {case_id}")
    if ids != {
        "one_by_one_trace", "two_by_two_trace", "three_by_three_prefix",
        "dense_four_full_trace", "breakdown_before_requested_length",
        "no_beta_needed_for_one_vector", "maximum_output_one_short",
        "invalid_asymmetric_matrix", "invalid_noninteger_matrix_entry",
        "invalid_order", "maximum_parseable_trailing_value", "null_input",
        "valid_null_output", "valid_zero_output_capacity",
    }:
        issues.append("fixture IDs differ from reviewed set")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    errors = static_issues()
    if errors:
        raise SystemExit("\n".join(errors))
