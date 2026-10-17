"""Oracle for the bounded, partial-pivot LUP decomposition workload."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 4
MIN_MATRIX_VALUE = -8
MAX_MATRIX_VALUE = 8
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_DIMENSION * MAX_DIMENSION + MAX_DIMENSION + 1
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _exact_integer(value: int | float) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


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
        [float(flat_matrix[row * dimension + col]) for col in range(dimension)]
        for row in range(dimension)
    ]
    return dimension, matrix


def _decompose(matrix: list[list[float]]) -> tuple[list[list[float]], list[int]] | None:
    """Preserve Dart Matrix.decompose's pivot selection and in-place order."""
    dimension = len(matrix)
    packed_lu = [row[:] for row in matrix]
    pivot = list(range(dimension + 1))

    for col in range(dimension):
        max_value = 0.0
        max_index = col
        for row in range(col, dimension):
            magnitude = abs(packed_lu[row][col])
            if magnitude > max_value:
                max_value = magnitude
                max_index = row

        if max_index != col:
            pivot[col], pivot[max_index] = pivot[max_index], pivot[col]
            packed_lu[col], packed_lu[max_index] = packed_lu[max_index], packed_lu[col]
            pivot[dimension] += 1

        pivot_value = packed_lu[col][col]
        if pivot_value == 0.0 or not math.isfinite(pivot_value):
            return None

        for row in range(col + 1, dimension):
            packed_lu[row][col] /= pivot_value
            if not math.isfinite(packed_lu[row][col]):
                return None
            for trailing_col in range(col + 1, dimension):
                packed_lu[row][trailing_col] -= (
                    packed_lu[row][col] * packed_lu[col][trailing_col]
                )
                if not math.isfinite(packed_lu[row][trailing_col]):
                    return None

    return packed_lu, pivot


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return packed LU followed by the source pivot vector, or an ABI error."""
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

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    dimension, matrix = decoded
    decomposition = _decompose(matrix)
    if decomposition is None:
        return INVALID_RESULT, []
    packed_lu, pivot = decomposition

    output = [value for row in packed_lu for value in row]
    output.extend(float(value) for value in pivot)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
