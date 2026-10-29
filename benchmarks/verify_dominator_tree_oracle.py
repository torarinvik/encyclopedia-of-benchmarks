"""Static workload/oracle consistency check; it does not build or run benchmarks."""

from __future__ import annotations

import json
from pathlib import Path

from dominator_tree_oracle import expected_output


ROOT = Path(__file__).resolve().parent
WORKLOAD = ROOT / "d" / "dominator_tree" / "workload.json"


def validate_workload() -> int:
    workload = json.loads(WORKLOAD.read_text(encoding="utf-8"))
    if workload.get("algorithm") != "dominator_tree" or workload.get("function_symbol") != "dominator_tree":
        raise ValueError("workload does not identify the dominator_tree ABI")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain at least one case")
    for case in cases:
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(input_length) is not int
                or (not input_is_null and input_length != len(values))
                or (input_is_null and values)):
            raise ValueError(f"incorrect input length in {case.get('id')}")
        expected_result, expected_bytes = expected_output(
            values,
            case.get("output_capacity"),
            case.get("output_is_null", False),
            input_is_null,
            input_length,
        )
        if case.get("expected_result") != expected_result:
            raise ValueError(f"incorrect result in {case.get('id')}")
        if case.get("expected_output_hex", "").lower() != expected_bytes.hex():
            raise ValueError(f"incorrect expected output in {case.get('id')}")
    return len(cases)


if __name__ == "__main__":
    print(f"validated {validate_workload()} dominator_tree workload cases against the set oracle")
