"""Oracle for the bounded C# LU elimination workload."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_DIMENSION = 0
MAX_DIMENSION = 4
MIN_MATRIX_VALUE = -1
MAX_MATRIX_VALUE = 1
MIN_RHS_VALUE = -8
MAX_RHS_VALUE = 8
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION + MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_DIMENSION
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
    expected_length = 1 + dimension * dimension + dimension
    if len(values) != expected_length:
        return None

    matrix_values = [_exact_integer(value) for value in values[1:1 + dimension * dimension]]
    if any(value is None or not MIN_MATRIX_VALUE <= value <= MAX_MATRIX_VALUE
           for value in matrix_values):
        return None
    rhs_values = [_exact_integer(value) for value in values[1 + dimension * dimension:]]
    if len(rhs_values) != dimension or any(
        value is None or not MIN_RHS_VALUE <= value <= MAX_RHS_VALUE
        for value in rhs_values
    ):
        return None

    matrix = [
        [float(matrix_values[row * dimension + column]) for column in range(dimension)]
        for row in range(dimension)
    ]
    rhs = [float(value) for value in rhs_values]
    return dimension, matrix, rhs


def _eliminate(
    matrix: list[list[float]], rhs: list[float]
) -> list[float] | None:
    dimension = len(matrix)
    lower = [[0.0] * dimension for _ in range(dimension)]
    upper = [[0.0] * dimension for _ in range(dimension)]

    for row in range(dimension):
        for column in range(row, dimension):
            lu_sum = 0.0
            for index in range(row):
                lu_sum += lower[row][index] * upper[index][column]
            upper[row][column] = matrix[row][column] - lu_sum

        pivot = upper[row][row]
        if pivot == 0.0 or not math.isfinite(pivot):
            return None

        for column in range(row, dimension):
            if row == column:
                lower[row][row] = 1.0
                continue
            lu_sum = 0.0
            for index in range(row):
                lu_sum += lower[column][index] * upper[index][row]
            lower[column][row] = (matrix[column][row] - lu_sum) / pivot
            if not math.isfinite(lower[column][row]):
                return None

    upper_transform = [0.0] * dimension
    solution = [0.0] * dimension
    for row in range(dimension):
        pivot_point_sum = 0.0
        for column in range(row):
            pivot_point_sum += upper_transform[column] * lower[row][column]
        upper_transform[row] = (rhs[row] - pivot_point_sum) / lower[row][row]
        if not math.isfinite(upper_transform[row]):
            return None

    for row in range(dimension - 1, -1, -1):
        pivot_point_sum = 0.0
        for column in range(row, dimension):
            pivot_point_sum += solution[column] * upper[row][column]
        pivot = upper[row][row]
        if pivot == 0.0 or not math.isfinite(pivot):
            return None
        solution[row] = (upper_transform[row] - pivot_point_sum) / pivot
        if not math.isfinite(solution[row]):
            return None
    return solution


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return the solution vector or the documented ABI error."""
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
    dimension, matrix, rhs = decoded
    solution = _eliminate(matrix, rhs)
    if solution is None:
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < dimension):
        return OUTPUT_ERROR, []
    return dimension, solution
