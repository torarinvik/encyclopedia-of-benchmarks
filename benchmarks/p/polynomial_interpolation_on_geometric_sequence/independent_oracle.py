"""Modular Vandermonde elimination for geometric-sequence interpolation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MODULUS, OUTPUT_ERROR,
    )
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MODULUS, OUTPUT_ERROR,
    )


def _vandermonde_solution(points: list[int], ys: list[int]) -> list[int]:
    n = len(points)
    matrix: list[list[int]] = []
    for x, y in zip(points, ys):
        row = [1]
        for _ in range(1, n):
            row.append(row[-1] * x % MODULUS)
        row.append(y)
        matrix.append(row)

    for column in range(n):
        pivot = next(row for row in range(column, n) if matrix[row][column] != 0)
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        inverse = pow(matrix[column][column], MODULUS - 2, MODULUS)
        matrix[column] = [(value * inverse) % MODULUS for value in matrix[column]]
        for row in range(n):
            if row == column:
                continue
            factor = matrix[row][column]
            if factor:
                matrix[row] = [
                    (left - factor * right) % MODULUS
                    for left, right in zip(matrix[row], matrix[column])
                ]
    return [matrix[row][n] for row in range(n)]


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
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""
    n, a, r = values[:3]
    if not 0 <= n <= MAX_N or len(values) != 3 + n:
        return INVALID, b""
    ys = list(values[3:])
    if not 0 <= a < MODULUS or not 0 <= r < MODULUS or any(not 0 <= y < MODULUS for y in ys):
        return INVALID, b""
    points: list[int] = []
    point = a
    for _ in range(n):
        points.append(point)
        point = point * r % MODULUS
    if len(set(points)) != n:
        return INVALID, b""

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    coefficients = _vandermonde_solution(points, ys)
    return byte_count, b"".join(struct.pack("<q", coefficient) for coefficient in coefficients)
