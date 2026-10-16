"""Bounded source-faithful oracle for Cholesky matrix decomposition."""

from __future__ import annotations

import math
import struct

MAX_DIMENSION = 6
MAX_ENTRY_MICRO = 1_000_000_000
SCALE = 1_000_000.0
SYMMETRY_ATOL = 1.0e-8
SYMMETRY_RTOL = 1.0e-5


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return row-major n-by-n lower-triangular binary64 bytes, or an error."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 1 + MAX_DIMENSION**2
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    dimension = values[0]
    if not 1 <= dimension <= MAX_DIMENSION or len(values) != 1 + dimension * dimension:
        return -1, b""
    entries = values[1:]
    if any(not -MAX_ENTRY_MICRO <= value <= MAX_ENTRY_MICRO for value in entries):
        return -1, b""

    n = dimension
    matrix = [[entries[row * n + column] / SCALE for column in range(n)]
              for row in range(n)]
    for row in range(n):
        for column in range(n):
            left, right = matrix[row][column], matrix[column][row]
            if abs(left - right) > SYMMETRY_ATOL + SYMMETRY_RTOL * abs(right):
                return -1, b""

    lower = [[0.0] * n for _ in range(n)]
    for row in range(n):
        for column in range(row + 1):
            dot = sum(lower[row][index] * lower[column][index]
                      for index in range(column))
            residual = matrix[row][column] - dot
            if row == column:
                if residual <= 0.0:
                    return -1, b""
                lower[row][column] = math.sqrt(residual)
            else:
                lower[row][column] = residual / lower[column][column]

    flat = [lower[row][column] for row in range(n) for column in range(n)]
    output = struct.pack("<" + "d" * len(flat), *flat)
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if len(output) > capacity:
            return -2, b""
    return len(output), output
