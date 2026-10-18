"""Oracle for a bounded classical Gram-Schmidt QR decomposition."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 4
MIN_MATRIX_VALUE = -4
MAX_MATRIX_VALUE = 4
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
    integer_matrix = [
        [flat_matrix[row * dimension + col] for col in range(dimension)]
        for row in range(dimension)
    ]
    if _determinant(integer_matrix) == 0:
        return None
    matrix = [[float(value) for value in row] for row in integer_matrix]
    return dimension, matrix


def _dot(left: list[float], right: list[float]) -> float:
    total = 0.0
    for index in range(len(left)):
        total += left[index] * right[index]
    return total


def _decompose(matrix: list[list[float]]) -> list[float] | None:
    """Preserve the pinned column-wise classical Gram-Schmidt order."""
    dimension = len(matrix)
    q = [[0.0] * dimension for _ in range(dimension)]
    r = [[0.0] * dimension for _ in range(dimension)]

    for col in range(dimension):
        source_column = [matrix[row][col] for row in range(dimension)]
        residual = source_column[:]
        for previous in range(col):
            basis = [q[row][previous] for row in range(dimension)]
            numerator = _dot(source_column, basis)
            denominator = _dot(basis, basis)
            if denominator == 0.0 or not math.isfinite(denominator):
                return None
            scalar = numerator / denominator
            for row in range(dimension):
                residual[row] -= scalar * basis[row]

        magnitude = math.sqrt(_dot(residual, residual))
        if magnitude == 0.0 or not math.isfinite(magnitude):
            return None
        for row in range(dimension):
            q[row][col] = residual[row] / magnitude

        q_column = [q[row][col] for row in range(dimension)]
        for source_col in range(col, dimension):
            source = [matrix[row][source_col] for row in range(dimension)]
            r[col][source_col] = _dot(q_column, source)

    output = [value for row in q for value in row]
    output.extend(value for row in r for value in row)
    if any(not math.isfinite(value) for value in output):
        return None
    return output


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return row-major Q then R, or the documented ABI error."""
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
    _, matrix = decoded
    output = _decompose(matrix)
    if output is None:
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
