"""Static package, fixture, and approximation-guarantee checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import (
    exact_optimum,
    expected_result as independent,
)
from .primary_oracle import (
    EPSILON_DENOMINATOR,
    MAX_CAPACITY,
    MAX_INPUT_LENGTH,
    MAX_ITEMS,
    MAX_PROFIT,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    MIN_CAPACITY,
    MIN_ITEMS,
    MIN_PROFIT,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/l/lawler_knapsack_profit_scaling_fptas"
SYMBOL = "lawler_knapsack_profit_scaling_fptas"
SOURCE_URL = "https://doi.org/10.1287/moor.4.4.339"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "all-items-fit-exact-solution",
    "dyadic-large-item-with-small-prefix-completion",
    "multiple-dyadic-groups-combine-in-frontier",
    "equal-q-group-keeps-lightest-items", "maximum-item-count-exact-solution",
    "maximum-result-bound",
    "invalid-empty-input", "null-input", "invalid-item-count-below-bound",
    "invalid-item-count-above-bound", "invalid-zero-weight",
    "invalid-weight-exceeds-capacity", "invalid-profit-below-bound",
    "invalid-truncated-pair", "invalid-trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "l" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
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
    profile = workload.get("algorithm_profile", {})
    source = workload.get("source", {})
    measurement = workload.get("measurement", {})
    if (workload.get("id") != "lawler-knapsack-dyadic-profit-scaling-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[capacity, n, (weight_0, profit_0), ..., (weight_(n-1), profit_(n-1))]"
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or input_spec.get("item_count_range") != [MIN_ITEMS, MAX_ITEMS]
            or input_spec.get("capacity_range") != [MIN_CAPACITY, MAX_CAPACITY]
            or input_spec.get("weight_range") != "1 <= weight <= capacity"
            or input_spec.get("profit_range") != [MIN_PROFIT, MAX_PROFIT]
            or input_spec.get("invalid_input_result") != -1
            or profile.get("epsilon") != f"1/{EPSILON_DENOMINATOR}"
            or profile.get("lower_bound") != "Sort by nonincreasing exact profit/weight ratio, breaking ties by input index. P0 is the maximum of the best ratio-prefix profit that fits before the first non-fitting item and the maximum individual profit."
            or profile.get("small_item_threshold") != "T=P0/4; an item is small when 4*profit <= P0."
            or profile.get("scale_factor") != "K=P0/16. The contract bounds n>=4 and profits>=32, so P0>=32 and K>1; this is Lawler's K>1 branch."
            or profile.get("dyadic_scaled_profit") != "For a large item in interval (2^k*T, 2^(k+1)*T], q=2^k*floor(16*profit/(2^k*P0))."
            or profile.get("equal_q_pruning") != "For each q retain at most floor(32/q) items of smallest weight, breaking ties by input index."
            or profile.get("large_item_dp") != "Process q groups in decreasing order; within each group choose a prefix of its retained items sorted by nondecreasing weight. Keep nondominated (total q, minimum weight) states."
            or profile.get("small_item_completion") != "For each large state, append the longest nonincreasing-profit/weight prefix of small items that fits the remaining capacity; ties use input index."
            or profile.get("complexity") != "The ports use insertion sorts and grouped frontier updates: O(n^2 + Q*(n+g)) time and O(n+Q) auxiliary space, where Q=32 and g<=n. Since Q is fixed by epsilon=1/2, the bounded profile is O(n^2) time and O(n) auxiliary space."
            or profile.get("tie_breaking") != "Maximize the scaled estimate P0*Q + 16*small_profit; then maximize actual profit, minimize total weight, and minimize the original-item bit mask."
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("meaning") != "(actual_selected_profit << 8) | selected_item_mask; bit i selects input item i."
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload identity, input framing, Lawler profile, or output bounds differ")

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
        length = case.get("input_length")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(expected) is not int or type(input_is_null) is not bool):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        primary_result = primary(values, input_is_null, length)
        independent_result = independent(values, input_is_null, length)
        if primary_result != expected:
            issues.append(f"primary-reference fixture mismatch: {case_id}")
        if independent_result != expected:
            issues.append(f"independent-reference fixture mismatch: {case_id}")
        if expected >= 0:
            approximate_profit = expected >> 8
            optimum = exact_optimum(values)
            if 2 * approximate_profit < optimum:
                issues.append(f"epsilon=1/2 guarantee failed: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
