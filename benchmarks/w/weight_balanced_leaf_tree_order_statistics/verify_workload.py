"""Static operation-contract, fixture, and source inventory review for WBLT."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_KEY, MAX_OPERATIONS, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
    MIN_KEY, NODE_CAPACITY, WORKSPACE_BYTES,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/w/weight_balanced_leaf_tree_order_statistics"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
SYMBOL = "weight_balanced_leaf_tree_order_statistics"
SOURCE_URL = "https://oi-wiki.org/ds/wblt/"
REQUIRED = {
    "empty-workload", "leaf-query-and-strict-neighbors",
    "duplicate-order-and-leftmost-removal", "missing-removal-and-empty-selection",
    "key-domain-boundaries", "remove-last-key-and-query-empty",
    "both-heavy-directions-and-deletion", "invalid-operation", "key-out-of-range",
    "negative-kth-index", "trailing-value", "missing-header", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "w" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[Q,(operation,argument)*Q]"
            or input_spec.get("operation_count_range") != [0, MAX_OPERATIONS]
            or input_spec.get("key_range") != [MIN_KEY, MAX_KEY]
            or input_spec.get("kth_argument_range") != [0, MAX_OPERATIONS - 1]
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_result") != -1
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("result_range") != "0..532480"
            or output_spec.get("invalid_result") != -1
            or workload.get("complexity", {}).get("time") != "O(Q log Q)"
            or workload.get("complexity", {}).get("auxiliary_space") != "O(Q)"
            or workload.get("complexity", {}).get("maximum_active_nodes") != NODE_CAPACITY - 2
            or workload.get("complexity", {}).get("balance_parameter") !=
               "alpha=1/4; one child is too heavy when it is greater than three times its sibling"
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        issues.append("workload identity, operation bounds, checksum, or workspace differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
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
        is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(is_null) is not bool
                or type(input_length) is not int
                or (is_null and (values or input_length != 0))
                or (not is_null and input_length != len(values))
                or type(expected) is not int):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if (primary(values, input_is_null=is_null, input_length=input_length) != expected
                or independent(values, input_is_null=is_null, input_length=input_length) != expected):
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
