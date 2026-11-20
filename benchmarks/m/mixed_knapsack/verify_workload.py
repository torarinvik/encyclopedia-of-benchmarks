"""Static package workload, reference, and port preflight."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "mixed_knapsack"
SOURCE_URL = "https://cp-algorithms.com/dynamic_programming/knapsack.html#mixed-knapsack"
PORTS = (
    "c/m/mixed_knapsack.c", "c3/m/mixed_knapsack.c3",
    "cpp/m/mixed_knapsack.cpp", "elisa/m/mixed_knapsack.elisa",
    "mojo/m/mixed_knapsack.mojo", "nim/m/mixed_knapsack.nim",
    "odin/m/mixed_knapsack.odin", "rust/m/mixed_knapsack.rs",
    "v/m/mixed_knapsack.v", "zig/m/mixed_knapsack.zig",
)
CASE_IDS = {
    "no-item-types", "zero-capacity", "two-single-use-types", "unbounded-only",
    "bounded-only", "all-three-modes", "zero-bounded-count", "zero-valued-types",
    "mixed-capacity-competition", "maximum-result-all-unbounded", "trailing-word",
    "maximum-parseable-trailing-word", "negative-type-count", "type-count-over-profile",
    "capacity-over-profile", "unknown-mode", "wrong-single-use-marker",
    "wrong-unbounded-marker", "bounded-limit-over-profile", "weight-zero",
    "value-over-profile", "truncated-record", "null-input",
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
    require(workload.get("source", {}).get("url") == SOURCE_URL, "source URL mismatch")
    input_spec = workload.get("input", {})
    require(input_spec.get("maximum_valid_length") == MAX_VALID_INPUT_LENGTH
            and input_spec.get("maximum_parseable_length") == MAX_PARSEABLE_INPUT_LENGTH
            and input_spec.get("invalid_input_result") == INVALID_RESULT,
            "input contract mismatch")
    require(workload.get("workspace", {}).get("bytes") == MAX_WORKSPACE_BYTES,
            "workspace mismatch")
    cases = workload.get("cases")
    require(isinstance(cases, list), "cases must be a list")
    seen: set[str] = set()
    for case in cases:
        require(isinstance(case, dict), "case must be an object")
        case_id = case.get("id")
        require(isinstance(case_id, str) and case_id not in seen, "duplicate case ID")
        seen.add(case_id)
        values = case.get("input_values")
        require(isinstance(values, list), f"{case_id}: input_values must be a list")
        null_input = case.get("input_is_null", False)
        frame_length = case.get("input_length")
        expected = case.get("expected_result")
        require(type(null_input) is bool, f"{case_id}: invalid null flag")
        require(type(frame_length) is int, f"{case_id}: invalid input length")
        require(type(expected) is int, f"{case_id}: invalid expected result")
        primary = expected_result(values, input_is_null=null_input, input_length=frame_length)
        independent = independent_expected_result(values, input_is_null=null_input,
                                                  input_length=frame_length)
        require(primary == expected, f"{case_id}: primary result mismatch")
        require(independent == expected, f"{case_id}: independent result mismatch")
    require(seen == CASE_IDS, "required fixture inventory differs")
    for relative in PORTS:
        source = (ROOT / relative).read_text(encoding="utf-8")
        require(SYMBOL in source, f"{relative}: exported symbol missing")
        require(re.search(r"\bTODO\b|PLACEHOLDER", source) is None,
                f"{relative}: placeholder remains")
    return len(cases)
