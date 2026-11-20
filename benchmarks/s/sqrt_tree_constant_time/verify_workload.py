"""Static workload and port preflight; this file is not executed here."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "sqrt_tree_constant_time"
SOURCE_URL = "https://cp-algorithms.com/data_structures/sqrt-tree.html#optimizing-the-query-complexity"
PORTS = (
    "c/s/sqrt_tree_constant_time.c", "c3/s/sqrt_tree_constant_time.c3",
    "cpp/s/sqrt_tree_constant_time.cpp", "elisa/s/sqrt_tree_constant_time.elisa",
    "mojo/s/sqrt_tree_constant_time.mojo", "nim/s/sqrt_tree_constant_time.nim",
    "odin/s/sqrt_tree_constant_time.odin", "rust/s/sqrt_tree_constant_time.rs",
    "v/s/sqrt_tree_constant_time.v", "zig/s/sqrt_tree_constant_time.zig",
)
CASE_IDS = {
    "cross-block-and-singleton-ranges", "select-every-layer-by-differing-bit",
    "singleton-array", "zero-query-array", "maximum-items-and-query-count",
    "invalid-range", "trailing-word", "maximum-parseable-trailing-word", "null-input",
}
ABI_CASE_IDS = {
    "short-output-capacity", "null-output-with-query", "null-output-with-no-queries",
    "null-input-precedes-output-check",
}

try:
    from .independent_oracle import expected_output as independent_output
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        BAD_OUTPUT_RESULT, INVALID_RESULT, MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH, MAX_WORKSPACE_BYTES,
        expected_output, expected_result,
    )
except ImportError:
    from independent_oracle import expected_output as independent_output  # type: ignore[no-redef]
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import (  # type: ignore[no-redef]
        BAD_OUTPUT_RESULT, INVALID_RESULT, MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH, MAX_WORKSPACE_BYTES,
        expected_output, expected_result,
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def verify_workload() -> tuple[int, int]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    require(workload.get("schema_version") == 1, "unsupported schema")
    require(workload.get("algorithm") == SYMBOL
            and workload.get("function_symbol") == SYMBOL, "symbol mismatch")
    require(workload.get("abi") == "i64_array_bytes_output", "ABI mismatch")
    require(workload.get("source", {}).get("url") == SOURCE_URL, "source URL mismatch")
    input_spec = workload.get("input", {})
    require(input_spec.get("maximum_valid_length") == MAX_VALID_INPUT_LENGTH
            and input_spec.get("maximum_parseable_length") == MAX_PARSEABLE_INPUT_LENGTH
            and input_spec.get("invalid_input_result") == INVALID_RESULT,
            "input contract mismatch")
    output_spec = workload.get("output", {})
    require(output_spec.get("maximum_output_bytes") == MAX_OUTPUT_BYTES
            and output_spec.get("insufficient_output_capacity_result") == BAD_OUTPUT_RESULT,
            "output contract mismatch")
    require(workload.get("workspace", {}).get("bytes") == MAX_WORKSPACE_BYTES,
            "workspace mismatch")

    cases = workload.get("cases")
    require(isinstance(cases, list), "cases must be a list")
    seen: set[str] = set()
    for case in cases:
        case_id = case.get("id")
        require(isinstance(case_id, str) and case_id not in seen, "duplicate case ID")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        null_input = case.get("input_is_null", False)
        expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        require(type(null_input) is bool, f"{case_id}: invalid null flag")
        require(expected_result(values, null_input, length) == case.get("expected_result"),
                f"{case_id}: primary result mismatch")
        require(independent_result(values, null_input, length) == case.get("expected_result"),
                f"{case_id}: independent result mismatch")
        require(expected_output(values, null_input, length) == expected_bytes,
                f"{case_id}: primary bytes mismatch")
        require(independent_output(values, null_input, length) == expected_bytes,
                f"{case_id}: independent bytes mismatch")
    require(seen == CASE_IDS, "required fixture inventory differs")

    abi_cases = workload.get("abi_cases")
    require(isinstance(abi_cases, list), "abi_cases must be a list")
    abi_seen: set[str] = set()
    for case in abi_cases:
        case_id = case.get("id")
        require(isinstance(case_id, str) and case_id not in abi_seen, "duplicate ABI case ID")
        abi_seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        null_input = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        semantic = expected_result(values, null_input, length)
        output = expected_output(values, null_input, length)
        if semantic == INVALID_RESULT:
            result, expected_bytes = INVALID_RESULT, b""
        elif (output and output_is_null) or capacity < len(output):
            result, expected_bytes = BAD_OUTPUT_RESULT, b""
        else:
            result, expected_bytes = semantic, output
        require(result == case.get("expected_result"), f"{case_id}: ABI result mismatch")
        require(expected_bytes == bytes.fromhex(case.get("expected_output_hex", "")),
                f"{case_id}: ABI output mismatch")
    require(abi_seen == ABI_CASE_IDS, "required ABI fixture inventory differs")

    for relative in PORTS:
        source = (ROOT / relative).read_text(encoding="utf-8")
        require(SYMBOL in source, f"{relative}: exported symbol missing")
        require(re.search(r"\bTODO\b|PLACEHOLDER", source) is None,
                f"{relative}: placeholder remains")
    return len(cases), len(abi_cases)
