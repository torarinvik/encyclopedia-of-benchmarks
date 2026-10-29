"""Static workload checks for rooted-tree isomorphism classification."""

from collections.abc import Mapping, Sequence

from rooted_tree_isomorphism_classification_oracle import expected_output


def verify_case(case: Mapping[str, object]) -> None:
    values = case.get("input_values")
    if not isinstance(values, list):
        raise ValueError("case input_values must be an array")
    result, output = expected_output(
        values,
        capacity=case.get("output_capacity"),
        output_is_null=case.get("output_is_null", False),
        input_is_null=case.get("input_is_null", False),
        input_length=case.get("input_length"),
    )
    expected_result = case.get("expected_result")
    expected_hex = case.get("expected_output_hex")
    if not isinstance(expected_result, int) or expected_hex != output.hex() or result != expected_result:
        raise AssertionError(
            f"{case.get('id')}: oracle produced ({result}, {output.hex()}), "
            f"expected ({expected_result}, {expected_hex})"
        )


def verify_workload(workload: Mapping[str, object]) -> None:
    if workload.get("algorithm") != "rooted_tree_isomorphism_classification":
        raise ValueError("workload algorithm name does not match this verifier")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        raise ValueError("workload must contain a cases array")
    identifiers: set[str] = set()
    for case in cases:
        if not isinstance(case, Mapping):
            raise ValueError("each case must be an object")
        identifier = case.get("id")
        if not isinstance(identifier, str) or identifier in identifiers:
            raise ValueError("workload case IDs must be unique strings")
        identifiers.add(identifier)
        verify_case(case)
