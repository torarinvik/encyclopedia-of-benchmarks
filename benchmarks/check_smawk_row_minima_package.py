"""Static inventory and fixture review; it does not launch language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/s/smawk_row_minima"

from s.smawk_row_minima.independent_oracle import (
    expected_output as independent_output,
    is_totally_monotone_for_row_minima,
)
from s.smawk_row_minima.primary_oracle import (
    MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)

LANGUAGE_PATHS = {
    "c": ROOT / "c/s/smawk_row_minima.c",
    "c3": ROOT / "c3/s/smawk_row_minima.c3",
    "cpp": ROOT / "cpp/s/smawk_row_minima.cpp",
    "elisa": ROOT / "elisa/s/smawk_row_minima.elisa",
    "mojo": ROOT / "mojo/s/smawk_row_minima.mojo",
    "nim": ROOT / "nim/s/smawk_row_minima.nim",
    "odin": ROOT / "odin/s/smawk_row_minima.odin",
    "rust": ROOT / "rust/s/smawk_row_minima.rs",
    "v": ROOT / "v/s/smawk_row_minima.v",
    "zig": ROOT / "zig/s/smawk_row_minima.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "smawk_row_minima" or workload.get("function_symbol") != "smawk_row_minima":
        issues.append("algorithm name or exported symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    input_meta = workload.get("input", {})
    if input_meta.get("row_count_range") != [1, 16] or input_meta.get("column_count_range") != [1, 16]:
        issues.append("matrix dimensions mismatch")
    if input_meta.get("maximum_valid_input_length") != 258 or input_meta.get("maximum_parseable_input_length") != 260:
        issues.append("input frame bounds mismatch")
    output_meta = workload.get("output", {})
    if output_meta.get("maximum_output_bytes") != MAX_OUTPUT_BYTES:
        issues.append("maximum output bound mismatch")
    if workload.get("workspace", {}).get("bytes", 0) != WORKSPACE_BYTES:
        issues.append("workspace metadata does not match the oracle")
    if workload.get("workspace", {}).get("bytes", 0) < output_meta.get("maximum_output_bytes", 1 << 60):
        issues.append("workspace must be at least the maximum output size")
    if workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call":
        issues.append("measurement model mismatch")
    if "A[i,j] > A[i,l] implies A[k,j] > A[k,l]" not in input_meta.get("matrix_promise", ""):
        issues.append("workload does not state the row-minimum total-monotonicity promise")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        if (isinstance(values, list) and len(values) >= 2
                and all(type(value) is int for value in values[:2])):
            row_count, column_count = values[:2]
            if (1 <= row_count <= 16 and 1 <= column_count <= 16
                    and len(values) == 2 + row_count * column_count
                    and not is_totally_monotone_for_row_minima(row_count, column_count, values[2:])):
                issues.append(f"fixture violates the total-monotonicity promise: {case_id}")
        if primary_output(values, **options) != expected:
            issues.append(f"primary fixture mismatch: {case_id}")
        if independent_output(values, **options) != expected:
            issues.append(f"independent fixture mismatch: {case_id}")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "smawk_row_minima" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "10.1007/BF01840359" not in readme or "column reduction" not in readme:
        issues.append("README is missing provenance or SMAWK method")
    if "10.1007/BF01840359" not in rights or "clean-room" not in rights:
        issues.append("rights note is missing provenance or clean-room statement")
    elisa = LANGUAGE_PATHS["elisa"].read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "input: i64&" not in elisa:
        issues.append("Elisa must use safe views internally and refs only at the ABI")
    if elisa.count("&") > 2:
        issues.append("Elisa contains non-ABI raw references")
    for name in ("smawk_row_minima_oracle.py", "smawk_row_minima_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing shared-suite oracle entry point: {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
