"""Oracle for bounded complete-group reversal of singly linked-list payloads."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_LIST_LENGTH = 256
MAX_VALID_INPUT_LENGTH = MAX_LIST_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_LIST_LENGTH * 4
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return complete-group-reversed values as little-endian i32 bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None:
        if input_length > len(values):
            return INVALID_RESULT, b""
        values = values[:input_length]
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""
    if len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT, b""

    group_size = values[0]
    if not 1 <= group_size <= MAX_LIST_LENGTH:
        return INVALID_RESULT, b""
    items = list(values[1:])
    for start in range(0, len(items) - group_size + 1, group_size):
        items[start:start + group_size] = reversed(items[start:start + group_size])
    encoded = struct.pack("<" + "i" * len(items), *items)
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
