"""Static workload and reference agreement checks for the SVD profile."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import expected_result as primary_result


def verify_workload(path: Path | None = None) -> None:
    package = Path(__file__).resolve().parent
    workload_path = package / "workload.json" if path is None else path
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if workload.get("algorithm") != "one_sided_jacobi_svd":
        raise ValueError("workload algorithm identity mismatch")
    if workload.get("function_symbol") != "one_sided_jacobi_svd":
        raise ValueError("workload symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        raise ValueError("workload ABI mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        input_length = case.get("input_length", len(values))
        is_null = case.get("input_is_null", False)
        expected = case["expected_result"]
        if primary_result(values, is_null, input_length) != expected:
            raise ValueError(f"primary oracle mismatch in {case.get('id')}")
        if independent_result(values, is_null, input_length) != expected:
            raise ValueError(f"independent oracle mismatch in {case.get('id')}")
