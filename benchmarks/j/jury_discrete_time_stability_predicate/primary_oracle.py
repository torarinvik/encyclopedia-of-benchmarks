"""Primary exact reference: division-free Jury coefficient table."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "jury_discrete_time_stability_predicate"
INVALID_RESULT = -1
MAX_DEGREE = 4
MAX_COEFFICIENT_ABS = 9
MAX_VALID_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7
WORKSPACE_BYTES = 1024


def _decode(values: Sequence[int], input_is_null: bool,
            input_length: int) -> list[int] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values)
            or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(word) is not int or word < -(1 << 63) or word >= (1 << 63)
           for word in values):
        return None
    degree = values[0]
    if type(degree) is not int or not 1 <= degree <= MAX_DEGREE:
        return None
    if input_length != degree + 2:
        return None
    coefficients = list(values[1:])
    if (len(coefficients) != degree + 1
            or any(abs(value) > MAX_COEFFICIENT_ABS for value in coefficients)
            or coefficients[0] == 0):
        return None
    return coefficients


def _strict_endpoint_conditions(coefficients: list[int]) -> bool:
    degree = len(coefficients) - 1
    at_one = sum(coefficients)
    at_minus_one = sum(
        coefficient if (degree - index) % 2 == 0 else -coefficient
        for index, coefficient in enumerate(coefficients)
    )
    return at_one > 0 and ((at_minus_one > 0) if degree % 2 == 0 else (at_minus_one < 0))


def _jury_table_is_strict(coefficients: list[int]) -> bool:
    row = coefficients[:]
    if row[0] < 0:
        row = [-value for value in row]
    if not _strict_endpoint_conditions(row):
        return False

    degree = len(row) - 1
    for current_degree in range(degree, 0, -1):
        leading = row[0]
        trailing = row[current_degree]
        trailing_magnitude = -trailing if trailing < 0 else trailing
        if leading <= trailing_magnitude:
            return False
        if current_degree == 1:
            break
        reduced = [
            leading * row[index] - trailing * row[current_degree - index]
            for index in range(current_degree)
        ]
        row = reduced
    return True


def expected_result(values: Sequence[int], input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    effective_length = (len(values) if input_length is None and isinstance(values, (list, tuple))
                        else input_length)
    if effective_length is None:
        return INVALID_RESULT
    coefficients = _decode(values, input_is_null, effective_length)
    if coefficients is None:
        return INVALID_RESULT
    return int(_jury_table_is_strict(coefficients))
