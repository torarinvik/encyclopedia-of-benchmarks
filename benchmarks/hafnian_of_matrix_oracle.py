"""Bounded exact oracle for a symmetric matrix hafnian."""

from functools import lru_cache
import struct

MOD = 998_244_353
MAX_N = 16
MAX_PARSEABLE_INPUT_LENGTH = 1 + MAX_N * MAX_N
MAX_OUTPUT_BYTES = 8


def _hafnian(matrix):
    n = len(matrix)

    @lru_cache(maxsize=None)
    def pair(remaining):
        if not remaining:
            return 1
        first = remaining[0]
        total = 0
        for position in range(1, len(remaining)):
            second = remaining[position]
            rest = remaining[1:position] + remaining[position + 1:]
            total += matrix[first][second] * pair(rest)
        return total % MOD

    return pair(tuple(range(n)))


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N, row-major matrix...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or not values):
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""

    n = values[0]
    if not 2 <= n <= MAX_N or n % 2 or len(values) != 1 + n * n:
        return -1, b""
    flat = values[1:]
    if any(value < 0 or value >= MOD for value in flat):
        return -1, b""
    matrix = [flat[row * n:(row + 1) * n] for row in range(n)]
    if any(matrix[row][row] != 0 for row in range(n)):
        return -1, b""
    if any(matrix[row][column] != matrix[column][row]
           for row in range(n) for column in range(row)):
        return -1, b""

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    output = struct.pack("<q", _hafnian(matrix))
    return len(output), output
