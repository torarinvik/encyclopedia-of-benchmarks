"""Static workload, oracle, attribution, and ten-port preflight."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "bounded_knapsack_binary_grouping"
SOURCE_URL = "https://cp-algorithms.com/dynamic_programming/knapsack.html#binary-grouping-optimization"
PORTS = (
    "c/b/bounded_knapsack_binary_grouping.c",
    "c3/b/bounded_knapsack_binary_grouping.c3",
    "cpp/b/bounded_knapsack_binary_grouping.cpp",
    "elisa/b/bounded_knapsack_binary_grouping.elisa",
    "mojo/b/bounded_knapsack_binary_grouping.mojo",
    "nim/b/bounded_knapsack_binary_grouping.nim",
    "odin/b/bounded_knapsack_binary_grouping.odin",
    "rust/b/bounded_knapsack_binary_grouping.rs",
    "v/b/bounded_knapsack_binary_grouping.v",
    "zig/b/bounded_knapsack_binary_grouping.zig",
)
CASE_IDS = {
    "no-item-types", "zero-capacity", "single-type-all-copies-fit",
    "non-power-of-two-remainder-bundle", "competing-item-types",
    "zero-count-valid", "zero-value-valid", "equal-value-alternatives",
    "maximum-capacity-and-result", "trailing-word",
    "maximum-parseable-trailing-word", "item-type-count-over-profile",
    "negative-capacity", "capacity-over-profile", "zero-weight-invalid",
    "weight-over-profile", "negative-value-invalid", "value-over-profile",
    "negative-count-invalid", "count-over-profile", "truncated-record", "null-input",
}

try:
    from .independent_oracle import expected_result as independent_expected_result
    from .primary_oracle import (
        INVALID_RESULT, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES, expected_result,
    )
except ImportError:
    from independent_oracle import expected_result as independent_expected_result  # type: ignore[no-redef]
    from primary_oracle import (  # type: ignore[no-redef]
        INVALID_RESULT, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES, expected_result,
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    require(workload.get("schema_version") == 1, "unsupported schema")
    require(workload.get("algorithm") == SYMBOL
            and workload.get("function_symbol") == SYMBOL, "symbol mismatch")
    require(workload.get("abi") == "i64_array_scalar", "ABI mismatch")
    require(workload.get("source", {}).get("url") == SOURCE_URL, "source mismatch")
    input_spec = workload.get("input", {})
    require(input_spec.get("maximum_valid_length") == MAX_VALID_INPUT_LENGTH
            and input_spec.get("maximum_parseable_length") == MAX_PARSEABLE_INPUT_LENGTH
            and input_spec.get("invalid_input_result") == INVALID_RESULT,
            "input bounds mismatch")
    require(input_spec.get("zero_count_valid") is True
            and input_spec.get("zero_value_valid") is True,
            "zero count/value contract mismatch")
    require(workload.get("workspace", {}).get("bytes") == MAX_WORKSPACE_BYTES,
            "workspace mismatch")

    cases = workload.get("cases")
    require(isinstance(cases, list), "cases must be a list")
    seen: set[str] = set()
    for case in cases:
        require(isinstance(case, dict), "case must be an object")
        case_id = case.get("id")
        require(isinstance(case_id, str) and case_id not in seen, "duplicate/invalid ID")
        seen.add(case_id)
        values = case.get("input_values")
        require(isinstance(values, list), f"{case_id}: input_values must be a list")
        null_input = case.get("input_is_null", False)
        declared_length = case.get("input_length")
        expected = case.get("expected_result")
        require(type(null_input) is bool, f"{case_id}: invalid null flag")
        require(type(declared_length) is int, f"{case_id}: invalid frame length")
        require(type(expected) is int, f"{case_id}: invalid expected result")
        primary = expected_result(values, input_is_null=null_input,
                                  input_length=declared_length)
        independent = independent_expected_result(values, input_is_null=null_input,
                                                  input_length=declared_length)
        require(primary == expected, f"{case_id}: primary result mismatch")
        require(independent == expected, f"{case_id}: independent result mismatch")
    require(seen == CASE_IDS, "required fixture inventory differs")

    for relative in PORTS:
        text = (ROOT / relative).read_text(encoding="utf-8")
        require(SYMBOL in text, f"{relative}: symbol missing")
        require(re.search(r"\bTODO\b|PLACEHOLDER", text) is None,
                f"{relative}: placeholder remains")
    return len(cases)
