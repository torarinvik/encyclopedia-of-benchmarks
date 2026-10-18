"""Oracle for the bounded symmetric 2x2 shifted-QR eigenvalue routine."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_DIMENSION = 2
MAX_DIMENSION = 2
MIN_MATRIX_VALUE = -9
MAX_MATRIX_VALUE = 9
CONVERGENCE_TOLERANCE = 1e-10
ABSOLUTE_TOLERANCE = 1e-8
RELATIVE_TOLERANCE = 1e-8
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_DIMENSION
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _dot(left: list[float], right: list[float]) -> float:
    total = 0.0
    for index in range(len(left)):
        total += left[index] * right[index]
    return total


def _qr(matrix: list[list[float]]) -> tuple[list[list[float]], list[list[float]]] | None:
    """Use the pinned column-wise classical Gram-Schmidt operation order."""
    dimension = len(matrix)
    q = [[0.0] * dimension for _ in range(dimension)]
    r = [[0.0] * dimension for _ in range(dimension)]
    for column in range(dimension):
        original = [matrix[row][column] for row in range(dimension)]
        residual = original[:]
        for previous in range(column):
            basis = [q[row][previous] for row in range(dimension)]
            denominator = _dot(basis, basis)
            if denominator == 0.0 or not math.isfinite(denominator):
                return None
            scalar = _dot(original, basis) / denominator
            for row in range(dimension):
                residual[row] -= scalar * basis[row]
        norm = math.sqrt(_dot(residual, residual))
        if norm == 0.0 or not math.isfinite(norm):
            return None
        for row in range(dimension):
            q[row][column] = residual[row] / norm
        for target in range(column, dimension):
            r[column][target] = _dot(
                [q[row][column] for row in range(dimension)],
                [matrix[row][target] for row in range(dimension)],
            )
    return q, r


def _decode(values: Sequence[float] | None) -> list[list[float]] | None:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    dimension_value = values[0]
    if (type(dimension_value) not in (int, float)
            or not math.isfinite(dimension_value)
            or not float(dimension_value).is_integer()
            or int(dimension_value) != MAX_DIMENSION
            or len(values) != 1 + MAX_DIMENSION * MAX_DIMENSION):
        return None
    entries: list[int] = []
    for value in values[1:]:
        if (type(value) not in (int, float) or not math.isfinite(value)
                or not float(value).is_integer()
                or not MIN_MATRIX_VALUE <= int(value) <= MAX_MATRIX_VALUE):
            return None
        entries.append(int(value))
    a00, a01, a10, a11 = entries
    if a01 != a10 or a01 == 0 or a00 == a11:
        return None
    return [[float(a00), float(a01)], [float(a10), float(a11)]]


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return the two eigenvalues in source deflation order."""
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
    matrix = _decode(values)
    if matrix is None:
        return INVALID_RESULT, []

    last_eigenvalue = 0.0
    iterations = 0
    while abs(matrix[1][0]) > CONVERGENCE_TOLERANCE:
        if iterations >= 256:
            return INVALID_RESULT, []
        last_eigenvalue = matrix[1][1]
        shifted = [row[:] for row in matrix]
        shifted[0][0] -= last_eigenvalue
        shifted[1][1] -= last_eigenvalue
        factorization = _qr(shifted)
        if factorization is None:
            return INVALID_RESULT, []
        q, r = factorization
        updated = [[0.0, 0.0], [0.0, 0.0]]
        for row in range(2):
            for column in range(2):
                for inner in range(2):
                    updated[row][column] += r[row][inner] * q[inner][column]
        updated[0][0] += last_eigenvalue
        updated[1][1] += last_eigenvalue
        matrix = updated
        iterations += 1

    output = [matrix[0][0], last_eigenvalue]
    if any(not math.isfinite(value) for value in output):
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
