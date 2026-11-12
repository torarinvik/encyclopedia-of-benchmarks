"""Independent small-matrix cofactor oracle for sparse determinant."""

from __future__ import annotations

import struct

MOD = 998244353
MAX_N = 8
MAX_K = 64
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_K
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8


def _cofactor_determinant(matrix: list[list[int]]) -> int:
    """Compute a small determinant by first-row cofactor expansion."""
    n = len(matrix)
    if n == 0:
        return 1
    if n == 1:
        return matrix[0][0] % MOD
    total = 0
    for column, value in enumerate(matrix[0]):
        if value == 0:
            continue
        minor = [row[:column] + row[column + 1:] for row in matrix[1:]]
        term = value * _cofactor_determinant(minor)
        total = (total + term if column % 2 == 0 else total - term) % MOD
    return total


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(status, bytes)`` for ``[N,K,(row,column,value)*K]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""

    n, k = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= k <= MAX_K:
        return -1, b""
    if input_length != 2 + 3 * k:
        return -1, b""

    matrix = [[0] * n for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for offset in range(2, input_length, 3):
        row, column, value = values[offset:offset + 3]
        if (not 0 <= row < n or not 0 <= column < n
                or not 1 <= value < MOD or (row, column) in seen):
            return -1, b""
        seen.add((row, column))
        matrix[row][column] = value

    determinant = _cofactor_determinant(matrix) % MOD
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return MAX_OUTPUT_BYTES, struct.pack("<q", determinant)
