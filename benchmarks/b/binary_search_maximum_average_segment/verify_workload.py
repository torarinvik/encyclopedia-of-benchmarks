"""Static workload, reference, and ten-port inventory preflight."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "binary_search_maximum_average_segment"
SOURCE_URL = "https://cp-algorithms.com/others/maximum_average_segment.html"
PORTS = (
    "c/b/binary_search_maximum_average_segment.c",
    "c3/b/binary_search_maximum_average_segment.c3",
    "cpp/b/binary_search_maximum_average_segment.cpp",
    "elisa/b/binary_search_maximum_average_segment.elisa",
    "mojo/b/binary_search_maximum_average_segment.mojo",
    "nim/b/binary_search_maximum_average_segment.nim",
    "odin/b/binary_search_maximum_average_segment.odin",
    "rust/b/binary_search_maximum_average_segment.rs",
    "v/b/binary_search_maximum_average_segment.v",
    "zig/b/binary_search_maximum_average_segment.zig",
)
CASE_IDS = {
    "single-positive", "minimum-length-one", "whole-array-minimum-length",
    "positive-fraction-floors-down", "negative-fraction-floors-down",
    "minimum-length-threshold-search", "all-negative-constrained",
    "minimum-valid-result", "maximum-valid-result", "zero-average-only-whole-array",
    "trailing-word", "maximum-parseable-trailing-word", "invalid-empty-sequence",
    "item-count-over-profile", "invalid-minimum-length-zero",
    "invalid-minimum-length-too-large", "value-below-profile",
    "value-above-profile", "truncated-values", "null-input",
}

try:
    from .independent_oracle import expected_result as independent_expected_result
    from .primary_oracle import (
        INVALID_RESULT,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_result,
    )
except ImportError:
    from independent_oracle import expected_result as independent_expected_result  # type: ignore[no-redef]
    from primary_oracle import (  # type: ignore[no-redef]
        INVALID_RESULT,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_result,
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
            "input bounds mismatch")
    require(workload.get("workspace", {}).get("bytes") == MAX_WORKSPACE_BYTES,
            "workspace bound mismatch")
    require(workload.get("output", {}).get("scale") == 1000
            and workload.get("output", {}).get("invalid_input_result") == INVALID_RESULT,
            "output contract mismatch")

    cases = workload.get("cases")
    require(isinstance(cases, list), "cases must be a list")
    seen: set[str] = set()
    for case in cases:
        require(isinstance(case, dict), "case must be an object")
        case_id = case.get("id")
        require(isinstance(case_id, str) and case_id not in seen,
                "duplicate or invalid case ID")
        seen.add(case_id)
        values = case.get("input_values")
        require(isinstance(values, list), f"{case_id}: input_values must be a list")
        null_input = case.get("input_is_null", False)
        declared_length = case.get("input_length")
        require(type(null_input) is bool, f"{case_id}: null flag must be boolean")
        require(type(declared_length) is int, f"{case_id}: input length must be integer")
        expected = case.get("expected_result")
        require(type(expected) is int, f"{case_id}: expected result must be integer")
        primary = expected_result(values, input_is_null=null_input,
                                  input_length=declared_length)
        independent = independent_expected_result(values, input_is_null=null_input,
                                                  input_length=declared_length)
        require(primary == expected, f"{case_id}: primary result mismatch")
        require(independent == expected, f"{case_id}: independent result mismatch")
    require(seen == CASE_IDS, "required fixture inventory differs")

    for relative in PORTS:
        source_text = (ROOT / relative).read_text(encoding="utf-8")
        require(SYMBOL in source_text, f"{relative}: exported symbol missing")
        require(re.search(r"\bTODO\b|PLACEHOLDER", source_text) is None,
                f"{relative}: placeholder remains")
    return len(cases)
