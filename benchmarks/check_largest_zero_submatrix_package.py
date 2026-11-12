"""Static inventory and fixture review for largest-zero-submatrix ports."""

from __future__ import annotations

import json
from pathlib import Path

from largest_zero_submatrix_oracle import expected_result as primary_result
from largest_zero_submatrix_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/l/largest_zero_submatrix"
PORTS = {
    "c": ROOT / "c/l/largest_zero_submatrix.c",
    "c3": ROOT / "c3/l/largest_zero_submatrix.c3",
    "cpp": ROOT / "cpp/l/largest_zero_submatrix.cpp",
    "elisa": ROOT / "elisa/l/largest_zero_submatrix.elisa",
    "mojo": ROOT / "mojo/l/largest_zero_submatrix.mojo",
    "nim": ROOT / "nim/l/largest_zero_submatrix.nim",
    "odin": ROOT / "odin/l/largest_zero_submatrix.odin",
    "rust": ROOT / "rust/l/largest_zero_submatrix.rs",
    "v": ROOT / "v/l/largest_zero_submatrix.v",
    "zig": ROOT / "zig/l/largest_zero_submatrix.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "largest_zero_submatrix":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "largest_zero_submatrix":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if input_contract.get("row_range") != [1, 16] or input_contract.get("column_range") != [1, 16]:
        issues.append("row/column bounds mismatch")
    if input_contract.get("maximum_valid_length") != 258:
        issues.append("maximum valid input length mismatch")
    if input_contract.get("maximum_parseable_length") != 259:
        issues.append("maximum parseable input length mismatch")
    if workload.get("output", {}).get("result_range") != [0, 256]:
        issues.append("result bounds mismatch")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "largest_zero_submatrix" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "https://cp-algorithms.com/dynamic_programming/zero_matrix.html" not in readme:
        issues.append("README missing algorithm source")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if ("input: view[i64]" not in source or "input: i64&" not in source
                or "last_one: mutable i64[" not in source):
            issues.append("Elisa must use safe views and fixed arrays internally, with refs only at the ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
