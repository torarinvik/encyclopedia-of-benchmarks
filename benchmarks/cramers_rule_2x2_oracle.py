"""Bounded byte-output oracle for the pinned 2x2 Cramer's rule solver."""

from __future__ import annotations

import struct

MAX_INPUT_LENGTH = 6
MAX_COEFFICIENT_ABSOLUTE_VALUE = 1_000_000
OUTPUT_BYTES = 16
INVALID_RESULT = -1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the ABI count and little-endian `(x, y)` binary64 payload."""
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)
            or any(abs(value) > MAX_COEFFICIENT_ABSOLUTE_VALUE for value in values)):
        return INVALID_RESULT, b""

    a1, b1, c1, a2, b2, c2 = values
    determinant = a1 * b2 - a2 * b1
    if determinant == 0:
        return INVALID_RESULT, b""

    determinant_x = c1 * b2 - c2 * b1
    determinant_y = a1 * c2 - a2 * c1
    x = determinant_x / determinant
    y = determinant_y / determinant
    return 2, struct.pack("<dd", x, y)
