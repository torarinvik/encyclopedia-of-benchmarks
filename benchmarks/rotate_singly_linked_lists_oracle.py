"""Oracle for the bounded Java right-rotation linked-list contract."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_K = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_N + 2:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""
    n, k = values[:2]
    if not 0 <= n <= MAX_N or not 0 <= k <= MAX_K or len(values) != n + 2:
        return INVALID_RESULT, b""
    items = values[2:]
    if any(value < -(1 << 31) or value >= (1 << 31) for value in items):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null:
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    rotated = items[:]
    if len(rotated) > 1:
        shift = k % len(rotated)
        if shift:
            rotated = rotated[-shift:] + rotated[:-shift]
    encoded = (n, *rotated)
    output = b"".join(struct.pack("<q", value) for value in encoded)
    if capacity is not None and capacity < len(output):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
