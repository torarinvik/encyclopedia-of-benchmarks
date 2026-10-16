"""Independent model for the pinned C partial-pivoting solver."""

from __future__ import annotations

import math
import struct

MAX_DIMENSION = 8
OUTPUT_BYTES_MAX = MAX_DIMENSION * 8


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_output(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= 73
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    n = values[0]
    if not 2 <= n <= MAX_DIMENSION or len(values) != 1 + n * n + n:
        return -1, b""
    if any(not -100 <= value <= 100 for value in values[1:]):
        return -1, b""
    matrix = [[_f32(values[1 + row * n + col]) for col in range(n)] + [_f32(0)]
              for row in range(n)]
    for row in range(n):
        matrix[row][n] = _f32(values[1 + n * n + row])

    for step in range(n - 1):
        pivot_row = step
        maximum = abs(matrix[step][step])
        for row in range(step, n):
            candidate = abs(matrix[row][step])
            if maximum < candidate:
                maximum, pivot_row = candidate, row
        if maximum == 0.0:
            return -1, b""
        matrix[step], matrix[pivot_row] = matrix[pivot_row], matrix[step]
        for row in range(step + 1, n):
            factor = _f32(-_f32(matrix[row][step] / matrix[step][step]))
            for col in range(n + 1):
                product = _f32(matrix[step][col] * factor)
                matrix[row][col] = _f32(matrix[row][col] + product)
    if matrix[n - 1][n - 1] == 0.0:
        return -1, b""

    solution = [0.0] * n
    for row in range(n - 1, -1, -1):
        total = _f32(0.0)
        col = n - 1
        while col > row:
            total = _f32(total + _f32(matrix[row][col] * solution[col]))
            col -= 1
        solution[row] = _f32(_f32(matrix[row][n] - total) / matrix[row][row])
    rounded = [float(format(value, ".2f")) for value in solution]
    encoded = b"".join(struct.pack("<d", value) for value in rounded)
    return len(encoded), encoded
