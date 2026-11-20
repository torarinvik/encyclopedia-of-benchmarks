"""Static workload/oracle consistency preflight; does not launch binaries."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import expected_result as primary_result  # type: ignore[no-redef]


ROOT = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "empty-item-set",
    "empty-set-positive-target",
    "all-items-fit",
    "break-item-exact-fit",
    "must-remove-earlier-break-items",
    "nearby-balanced-state-no-exact-fill",
    "duplicate-weights-and-zero-capacity",
    "maximum-items-and-weight",
    "trailing-word",
    "one-over-valid-parseable-length",
    "invalid-item-count",
    "negative-target",
    "target-over-bound",
    "zero-weight-out-of-profile",
    "weight-over-bound",
    "incorrect-item-count-framing",
    "null-input",
}


def check_workload() -> None:
    workload = json.loads((ROOT / "workload.json").read_text(encoding="utf-8"))
    if workload.get("algorithm") != "pisinger_bounded_weight_subset_sum":
        raise ValueError("workload algorithm id mismatch")
    if workload.get("abi") != "i64_array_scalar":
        raise ValueError("workload ABI mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        raise ValueError("workload cases must be an array")
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if set(ids) != REQUIRED_CASES or len(ids) != len(REQUIRED_CASES):
        raise ValueError("required case inventory mismatch")
    for case in cases:
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if not isinstance(values, list):
            raise ValueError(f"input_values must be a list in {case['id']}")
        primary = primary_result(values, input_is_null=is_null, input_length=length)
        independent = independent_result(values, input_is_null=is_null, input_length=length)
        if primary != expected or independent != expected:
            raise ValueError(f"oracle/workload mismatch in {case['id']}")
        if is_null and length != 0:
            raise ValueError("null-input fixture must have zero encoded length")
        if not is_null and (not isinstance(length, int) or length != len(values)):
            raise ValueError(f"encoded length mismatch in {case['id']}")


if __name__ == "__main__":
    check_workload()
