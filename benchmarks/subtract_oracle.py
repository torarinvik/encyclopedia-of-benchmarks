"""Independent bounded integer oracle for elementwise matrix subtraction."""
from __future__ import annotations

import struct
from typing import Sequence

MAX_DIMENSION = 16
MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION
MAX_INPUT_LENGTH = 4 + 2 * MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_CELLS * 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -2
DIMENSION_MISMATCH_RESULT = -1
INSUFFICIENT_OUTPUT_RESULT = -3


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (result, output bytes) under the packed subtract ABI."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 4
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    rows_a, columns_a = values[0], values[1]
    if not 0 <= rows_a <= MAX_DIMENSION or not 0 <= columns_a <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    if rows_a == 0 and columns_a != 0:
        return INVALID_RESULT, b""
    cells_a = rows_a * columns_a
    b_dimensions = 2 + cells_a
    if b_dimensions + 2 > len(values):
        return INVALID_RESULT, b""

    rows_b, columns_b = values[b_dimensions:b_dimensions + 2]
    if not 0 <= rows_b <= MAX_DIMENSION or not 0 <= columns_b <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    if rows_b == 0 and columns_b != 0:
        return INVALID_RESULT, b""
    cells_b = rows_b * columns_b
    if len(values) != b_dimensions + 2 + cells_b:
        return INVALID_RESULT, b""
    if rows_a != rows_b or columns_a != columns_b:
        return DIMENSION_MISMATCH_RESULT, b""

    a = values[2:b_dimensions]
    b = values[b_dimensions + 2:]
    if any(not I32_MIN <= value <= I32_MAX for value in (*a, *b)):
        return INVALID_RESULT, b""

    encoded = b"".join(struct.pack("<I", (left - right) & 0xFFFFFFFF) for left, right in zip(a, b))
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if cells_a == 0:
        return 0, b""
    if output_is_null or output_capacity < len(encoded):
        return INSUFFICIENT_OUTPUT_RESULT, b""
    return cells_a, encoded
