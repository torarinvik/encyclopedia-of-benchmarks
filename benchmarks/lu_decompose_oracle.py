"""Oracle for the bounded no-pivot Doolittle LU decomposition workload."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 4
MIN_MATRIX_VALUE = -8
MAX_MATRIX_VALUE = 8
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_DIMENSION * MAX_DIMENSION
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
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None

    dimension = _exact_integer(values[0])
    if dimension is None or not MIN_DIMENSION <= dimension <= MAX_DIMENSION:
        return None
    if len(values) != 1 + dimension * dimension:
        return None

    flat_matrix = [_exact_integer(value) for value in values[1:]]
    if any(
        value is None or not MIN_MATRIX_VALUE <= value <= MAX_MATRIX_VALUE
        for value in flat_matrix
    ):
        return None
    matrix = [
        [float(flat_matrix[row * dimension + col]) for col in range(dimension)]
        for row in range(dimension)
    ]
    return dimension, matrix


def _decompose(matrix: list[list[float]]) -> tuple[list[list[float]], list[list[float]]] | None:
    dimension = len(matrix)
    lower = [[0.0] * dimension for _ in range(dimension)]
    upper = [[0.0] * dimension for _ in range(dimension)]

    for row in range(dimension):
        for col in range(row, dimension):
            lu_sum = 0.0
            for index in range(row):
                lu_sum += lower[row][index] * upper[index][col]
            upper[row][col] = matrix[row][col] - lu_sum

        if upper[row][row] == 0.0 or not math.isfinite(upper[row][row]):
            return None

        for col in range(row, dimension):
            if row == col:
                lower[row][col] = 1.0
                continue
            lu_sum = 0.0
            for index in range(row):
                lu_sum += lower[col][index] * upper[index][row]
            lower[col][row] = (matrix[col][row] - lu_sum) / upper[row][row]
            if not math.isfinite(lower[col][row]):
                return None

    if any(not math.isfinite(value) for row in upper for value in row):
        return None
    return lower, upper


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return row-major L then U, or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
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
    factors = _decompose(matrix)
    if factors is None:
        return INVALID_RESULT, []
    lower, upper = factors

    output = [value for row in lower for value in row]
    output.extend(value for row in upper for value in row)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return 2 * dimension * dimension, output
