"""Scalar Boolean-elimination oracle for determinant modulo two."""

import struct

MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = 1 + MAX_N * MAX_N
MAX_OUTPUT_BYTES = 8


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N, row-major binary matrix...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)
            or any(type(value) is not int for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n * n:
        return -1, b""
    flat = values[1:]
    if any(value not in (0, 1) for value in flat):
        return -1, b""
    matrix = [list(flat[row * n:(row + 1) * n]) for row in range(n)]

    rank = 0
    for column in range(n):
        pivot = next((row for row in range(rank, n) if matrix[row][column]), None)
        if pivot is None:
            continue
        matrix[rank], matrix[pivot] = matrix[pivot], matrix[rank]
        for row in range(rank + 1, n):
            if matrix[row][column]:
                for next_column in range(column, n):
                    matrix[row][next_column] ^= matrix[rank][next_column]
        rank += 1
    determinant = int(rank == n)

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return 8, struct.pack("<q", determinant)
