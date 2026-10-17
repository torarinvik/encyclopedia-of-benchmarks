"""Reference oracle for the bounded Python PowerSort contract."""

from __future__ import annotations

import struct

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VALUES = 64
MAX_VALID_INPUT_LENGTH = 2 + MAX_VALUES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_OUTPUT_BYTES = 8 * MAX_VALUES
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_RESULT = -2


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return bytes written and the sorted little-endian i64 array."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    reverse, count = values[0], values[1]
    if reverse not in (0, 1) or not 0 <= count <= MAX_VALUES:
        return INVALID_RESULT, b""
    if len(values) != 2 + count:
        return INVALID_RESULT, b""
    cells = values[2:]
    if any(value < MIN_VALUE or value > MAX_VALUE for value in cells):
        return INVALID_RESULT, b""

    if count == 0:
        return 0, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < 8 * count:
        return INSUFFICIENT_OUTPUT_RESULT, b""

    ordered = sorted(cells, reverse=(reverse == 1))
    return 8 * count, struct.pack(f"<{count}q", *ordered)
