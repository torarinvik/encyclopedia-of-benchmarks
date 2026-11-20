"""Independent reference: Schur–Cohn matrix and exact principal minors."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_COEFFICIENT_ABS,
    MAX_DEGREE,
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
    if (len(coefficients) != degree + 1
            or any(abs(value) > MAX_COEFFICIENT_ABS for value in coefficients)
            or coefficients[0] == 0):
        return None
    return coefficients


def _minor_determinant(matrix: list[list[int]]) -> int:
    order = len(matrix)
    if order == 1:
        return matrix[0][0]
    total = 0
    for column in range(order):
        entry = matrix[0][column]
        if entry == 0:
            continue
        minor = [row[:column] + row[column + 1:] for row in matrix[1:]]
        sign = 1 if column % 2 == 0 else -1
        total += sign * entry * _minor_determinant(minor)
    return total


def _schur_cohn_minors_positive(coefficients: list[int]) -> bool:
    degree = len(coefficients) - 1
    x = [[0] * degree for _ in range(degree)]
    y = [[0] * degree for _ in range(degree)]
    for row in range(degree):
        for column in range(row + 1):
            offset = row - column
            x[row][column] = coefficients[offset]
            y[row][column] = coefficients[degree - offset]

    schur_matrix = [[0] * degree for _ in range(degree)]
    for row in range(degree):
        for column in range(degree):
            x_product = sum(x[row][index] * x[column][index]
                            for index in range(degree))
            y_product = sum(y[row][index] * y[column][index]
                            for index in range(degree))
            schur_matrix[row][column] = x_product - y_product

    for size in range(1, degree + 1):
        leading_block = [row[:size] for row in schur_matrix[:size]]
        if _minor_determinant(leading_block) <= 0:
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
    return int(_schur_cohn_minors_positive(coefficients))
