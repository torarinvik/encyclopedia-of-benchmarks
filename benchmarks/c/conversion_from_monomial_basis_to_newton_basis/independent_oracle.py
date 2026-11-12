"""Newton-basis matrix oracle using modular Gaussian elimination."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX,
        I64_MIN,
        INVALID,
        MAX_INPUT_LENGTH,
        MAX_N,
        MODULUS,
        OUTPUT_ERROR,
    )
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import (
        I64_MAX,
        I64_MIN,
        INVALID,
        MAX_INPUT_LENGTH,
        MAX_N,
        MODULUS,
        OUTPUT_ERROR,
    )


def _convert_by_basis_matrix(coefficients: list[int], nodes: list[int]) -> list[int]:
    n = len(coefficients)
    basis = [1]
    matrix = [[0] * (n + 1) for _ in range(n)]
    for column in range(n):
        for degree, coefficient in enumerate(basis):
            matrix[degree][column] = coefficient
        if column < n - 1:
            node = nodes[column]
            next_basis = [0] * (len(basis) + 1)
            for degree, coefficient in enumerate(basis):
                next_basis[degree] = (next_basis[degree] - node * coefficient) % MODULUS
                next_basis[degree + 1] = (next_basis[degree + 1] + coefficient) % MODULUS
            basis = next_basis
    for degree, coefficient in enumerate(coefficients):
        matrix[degree][n] = coefficient

    for column in range(n):
        pivot = next(row for row in range(column, n) if matrix[row][column] != 0)
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        scale = pow(matrix[column][column], MODULUS - 2, MODULUS)
        for j in range(column, n + 1):
            matrix[column][j] = matrix[column][j] * scale % MODULUS
        for row in range(n):
            if row == column:
                continue
            factor = matrix[row][column]
            if factor:
                for j in range(column, n + 1):
                    matrix[row][j] = (
                        matrix[row][j] - factor * matrix[column][j]
                    ) % MODULUS
    return [matrix[i][n] for i in range(n)]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID, b""
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return INVALID, b""
    coefficients = list(values[1 : n + 1])
    nodes = list(values[n + 1 :])
    if any(not 0 <= value < MODULUS for value in coefficients + nodes):
        return INVALID, b""
    byte_count = 8 * n
    if output_is_null or (
        output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < byte_count)
    ):
        return OUTPUT_ERROR, b""
    answer = _convert_by_basis_matrix(coefficients, nodes)
    return byte_count, b"".join(struct.pack("<q", value) for value in answer)
