"""Primary reference: construct the Routh array with exact fractions."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

ALGORITHM = "routh_hurwitz_stability_predicate"
INVALID_RESULT = -1
MAX_DEGREE = 4
MAX_COEFFICIENT_ABS = 3
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
    if (len(coefficients) != degree + 1 or not 1 <= coefficients[0] <= MAX_COEFFICIENT_ABS
            or any(abs(value) > MAX_COEFFICIENT_ABS for value in coefficients)):
        return None
    return coefficients


def _routh_positive_first_column(coefficients: list[int]) -> bool:
    degree = len(coefficients) - 1
    width = (degree + 2) // 2
    table = [[Fraction(0) for _ in range(width)] for _ in range(degree + 1)]
    for column in range(width):
        even_index = 2 * column
        odd_index = even_index + 1
        if even_index <= degree:
            table[0][column] = Fraction(coefficients[even_index])
        if odd_index <= degree:
            table[1][column] = Fraction(coefficients[odd_index])

    if all(value == 0 for value in table[1]) or table[1][0] <= 0:
        return False
    for row in range(2, degree + 1):
        pivot = table[row - 1][0]
        if pivot == 0:
            return False
        for column in range(width):
            upper_left = table[row - 1][0]
            upper_next = table[row - 2][column + 1] if column + 1 < width else Fraction(0)
            lower_left = table[row - 2][0]
            lower_next = table[row - 1][column + 1] if column + 1 < width else Fraction(0)
            table[row][column] = (upper_left * upper_next - lower_left * lower_next) / pivot
        if all(value == 0 for value in table[row]) or table[row][0] <= 0:
            return False
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
    return int(_routh_positive_first_column(coefficients))
