"""Vandermonde-system reference for finite-field interpolation evaluation."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "barycentric_lagrange_evaluation"
MODULUS = 998244353
MAX_NODES = 8
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_NODES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 512
INVALID_RESULT = -1


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[list[int], list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_NODES or input_length != 2 + 2 * count:
        return None
    nodes = list(values[1:1 + count])
    ordinates = list(values[1 + count:1 + 2 * count])
    query = values[-1]
    if (any(value < 0 or value >= MODULUS for value in (*nodes, *ordinates, query))
            or len(set(nodes)) != count):
        return None
    return nodes, ordinates, query


def _solve_vandermonde(nodes: Sequence[int], ordinates: Sequence[int]) -> list[int]:
    """Recover monomial coefficients with modular Gauss-Jordan elimination."""
    count = len(nodes)
    matrix: list[list[int]] = []
    for node, ordinate in zip(nodes, ordinates):
        row = [1]
        for _ in range(1, count):
            row.append(row[-1] * node % MODULUS)
        row.append(ordinate)
        matrix.append(row)

    for column in range(count):
        pivot = next(row for row in range(column, count) if matrix[row][column] != 0)
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        scale = pow(matrix[column][column], MODULUS - 2, MODULUS)
        for entry in range(column, count + 1):
            matrix[column][entry] = matrix[column][entry] * scale % MODULUS
        for row in range(count):
            if row == column:
                continue
            factor = matrix[row][column]
            if factor:
                for entry in range(column, count + 1):
                    matrix[row][entry] = (matrix[row][entry]
                                          - factor * matrix[column][entry]) % MODULUS
    return [matrix[row][count] for row in range(count)]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    nodes, ordinates, query = parsed
    coefficients = _solve_vandermonde(nodes, ordinates)
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * query + coefficient) % MODULUS
    return result
