"""Static package inventory checks; this module is not run during quiet profiling."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import expected_result as primary_result

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/o/one_sided_jacobi_svd"
PORTS = {
    "c": ROOT / "c/o/one_sided_jacobi_svd.c",
    "c3": ROOT / "c3/o/one_sided_jacobi_svd.c3",
    "cpp": ROOT / "cpp/o/one_sided_jacobi_svd.cpp",
    "elisa": ROOT / "elisa/o/one_sided_jacobi_svd.elisa",
    "mojo": ROOT / "mojo/o/one_sided_jacobi_svd.mojo",
    "nim": ROOT / "nim/o/one_sided_jacobi_svd.nim",
    "odin": ROOT / "odin/o/one_sided_jacobi_svd.odin",
    "rust": ROOT / "rust/o/one_sided_jacobi_svd.rs",
    "v": ROOT / "v/o/one_sided_jacobi_svd.v",
    "zig": ROOT / "zig/o/one_sided_jacobi_svd.zig",
}


def static_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    if workload.get("algorithm") != "one_sided_jacobi_svd":
        issues.append("workload algorithm mismatch")
    if workload.get("function_symbol") != "one_sided_jacobi_svd":
        issues.append("workload symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    spec = workload.get("input")
    if (not isinstance(spec, dict)
            or spec.get("layout") != "[m,n,row-major matrix entries]"
            or spec.get("matrix_rows") != "1<=n<=m<=6"
            or spec.get("matrix_columns") != "1<=n<=6"
            or spec.get("maximum_valid_values") != 38
            or spec.get("maximum_parseable_values") != 39
            or spec.get("entry_range") != [-8, 8]):
        issues.append("input bounds mismatch")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port")
        elif "one_sided_jacobi_svd" not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} export symbol missing")
    for name in ("README.md", "RIGHTS.md", "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "INVENTORY.json", "INVENTORY.md"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    required = {
        "single-column-3-4", "diagonal-sorted", "equal-singular-values", "zero-matrix",
        "rank-one-rectangular", "three-singular-values", "maximum-frame-rank-one",
        "wrong-length", "non-tall-shape", "entry-out-of-range", "trailing-value",
        "null-input", "null-at-parseable-limit",
    }
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else None)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(null) is not bool or type(length) is not int
                or (null and (values or not 0 <= length <= 39))
                or (not null and (length != len(values) or length > 39))
                or type(expected) is not int):
            issues.append(f"invalid workload framing: {case_id}")
            continue
        try:
            if (primary_result(values, null, length) != expected
                    or independent_result(values, null, length) != expected):
                issues.append(f"reference disagreement: {case_id}")
        except (ArithmeticError, IndexError, TypeError, ValueError):
            issues.append(f"reference rejected malformed framing: {case_id}")
    if required - seen:
        issues.append("missing required workload cases: " + ", ".join(sorted(required - seen)))
    return issues
