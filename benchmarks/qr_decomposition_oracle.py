"""Ideal property targets for the bounded QR factorization workload."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 4
MIN_MATRIX_VALUE = -1
MAX_MATRIX_VALUE = 1
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 3
ABSOLUTE_TOLERANCE = 1e-8
RELATIVE_TOLERANCE = 1e-8
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _exact_integer(value: int | float) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


def _determinant(matrix: list[list[int]]) -> int:
    """Return the exact determinant; dimensions are bounded to at most four."""
    dimension = len(matrix)
    if dimension == 1:
        return matrix[0][0]
    return sum(
        (-1 if col % 2 else 1)
        * matrix[0][col]
        * _determinant([
            [matrix[row][inner_col] for inner_col in range(dimension)
             if inner_col != col]
            for row in range(1, dimension)
        ])
        for col in range(dimension)
    )


def _leading_principal_minors_are_nonzero(matrix: list[list[int]]) -> bool:
    for size in range(1, len(matrix) + 1):
        leading_block = [row[:size] for row in matrix[:size]]
        if _determinant(leading_block) == 0:
            return False
    return True


def _decode_input(values: Sequence[float] | None):
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None

    dimension = _exact_integer(values[0])
    if dimension is None or not MIN_DIMENSION <= dimension <= MAX_DIMENSION:
        return None
    if len(values) != 1 + dimension * dimension:
        return None

    flat_matrix = [_exact_integer(value) for value in values[1:]]
    if any(value is None or not MIN_MATRIX_VALUE <= value <= MAX_MATRIX_VALUE
           for value in flat_matrix):
        return None
    matrix = [
        [flat_matrix[row * dimension + col] for col in range(dimension)]
        for row in range(dimension)
    ]
    if not _leading_principal_minors_are_nonzero(matrix):
        return None
    return dimension, matrix


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return ideal zero factorization errors, or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int
                                        or output_capacity < 0):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    if _decode_input(values) is None:
        return INVALID_RESULT, []
    output = [0.0, 0.0, 0.0]
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
