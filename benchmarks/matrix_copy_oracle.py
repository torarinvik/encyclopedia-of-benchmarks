"""Oracle for bounded integer-matrix deep-copy output."""

from __future__ import annotations

import struct

MAX_DIMENSION = 32
MAX_INPUT_LENGTH = 2 + MAX_DIMENSION * MAX_DIMENSION
MAX_OUTPUT_BYTES = (2 + MAX_DIMENSION * MAX_DIMENSION) * 8
INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return the copied matrix shape and values as little-endian i64 data."""
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    rows, columns = values[:2]
    if not 0 <= rows <= MAX_DIMENSION or not 0 <= columns <= MAX_DIMENSION:
        return -1, b""
    element_count = rows * columns
    if len(values) != 2 + element_count:
        return -1, b""
    elements = values[2:]
    if any(not INT32_MIN <= value <= INT32_MAX for value in elements):
        return -1, b""

    # Go Matrix.Copy returns the zero Matrix when either reported dimension is zero.
    result_rows, result_columns = (0, 0) if rows == 0 or columns == 0 else (rows, columns)
    result = [result_rows, result_columns, *elements]
    encoded = struct.pack("<" + "q" * len(result), *result)
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if len(encoded) > capacity:
            return -2, b""
    return len(encoded), encoded
