"""Package-local static verifier helpers for segment-tree-beats workload cases."""

from collections.abc import Mapping, Sequence

from segment_tree_beats_oracle import expected_output


def verify_result(input_values: Sequence[int], actual_result: int) -> None:
    expected = expected_output(input_values)
    if actual_result != expected:
        raise AssertionError(f"segment_tree_beats returned {actual_result}; expected {expected}")


def verify_workload_cases(workload: Mapping[str, object]) -> None:
    cases = workload.get("cases")
    if not isinstance(cases, list):
        raise ValueError("workload must contain a cases array")
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("each workload case must be an object")
        values = case.get("input_values")
        result = case.get("expected_result")
        if not isinstance(values, list) or not isinstance(result, int):
            raise ValueError("each case needs input_values and expected_result")
        verify_result(values, result)
