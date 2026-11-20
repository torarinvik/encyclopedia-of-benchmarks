"""Independent reference: test Hurwitz leading principal determinants."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_DEGREE,
    MAX_COEFFICIENT_ABS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
)


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


def _determinant(matrix: list[list[int]]) -> int:
    size = len(matrix)
    if size == 0:
        return 1
    if size == 1:
        return matrix[0][0]
    total = 0
    for column, value in enumerate(matrix[0]):
        if value == 0:
            continue
        minor = [row[:column] + row[column + 1:] for row in matrix[1:]]
        sign = -1 if column % 2 else 1
        total += sign * value * _determinant(minor)
    return total


def _hurwitz_determinants_positive(coefficients: list[int]) -> bool:
    degree = len(coefficients) - 1
    hurwitz = []
    for row in range(degree):
        current = []
        for column in range(degree):
            coefficient_index = 2 * column - row + 1
            current.append(coefficients[coefficient_index]
                           if 0 <= coefficient_index <= degree else 0)
        hurwitz.append(current)
    for size in range(1, degree + 1):
        leading_block = [row[:size] for row in hurwitz[:size]]
        if _determinant(leading_block) <= 0:
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
    return int(_hurwitz_determinants_positive(coefficients))
