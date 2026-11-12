"""Exact cofactor-expansion oracle for bounded arbitrary-modulus determinants."""

import struct

MAX_N = 8
MAX_MODULUS = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8


def _determinant(matrix):
    """Compute the exact integer determinant by first-row cofactor expansion."""
    size = len(matrix)
    if size == 0:
        return 1
    total = 0
    for column, value in enumerate(matrix[0]):
        if value == 0:
            continue
        minor = [row[:column] + row[column + 1:] for row in matrix[1:]]
        term = value * _determinant(minor)
        total += term if column % 2 == 0 else -term
    return total


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(status, bytes)`` for ``[N, modulus, row-major matrix...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""

    n, modulus = values[:2]
    if not 0 <= n <= MAX_N or not 2 <= modulus <= MAX_MODULUS:
        return -1, b""
    if len(values) != 2 + n * n:
        return -1, b""
    entries = values[2:]
    if any(not 0 <= entry < modulus for entry in entries):
        return -1, b""
    matrix = [list(entries[row * n:(row + 1) * n]) for row in range(n)]
    determinant = _determinant(matrix) % modulus

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return 8, struct.pack("<q", determinant)
