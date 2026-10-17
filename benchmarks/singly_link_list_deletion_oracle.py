"""Oracle for deleting one valid 1-based position from a bounded singly linked list."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = MAX_N + 3  # includes a parseable n=65 malformed frame
MAX_VALID_INPUT_LENGTH = MAX_N + 2
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
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""
    n, position = values[:2]
    if not 1 <= n <= MAX_N or len(values) != n + 2 or not 1 <= position <= n:
        return INVALID_RESULT, b""
    items = values[2:]
    if any(value < -(1 << 31) or value >= (1 << 31) for value in items):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null:
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    remaining = items[:position - 1] + items[position:]
    output = b"".join(struct.pack("<i", value) for value in remaining)
    if capacity is not None and capacity < len(output):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
