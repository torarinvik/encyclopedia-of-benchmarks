"""Oracle for the bounded recursive stack-reversal benchmark."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ELEMENTS = 16
MAX_PARSEABLE_INPUT_LENGTH = MAX_ELEMENTS + 2
MAX_ABS_VALUE = 1_000_000
MAX_OUTPUT_BYTES = 8 * (MAX_ELEMENTS + 1)
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return byte status and serialized reversed bottom-to-top stack."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (values is None or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""

    raw_count = values[0]
    if not 0 <= raw_count <= MAX_ELEMENTS or len(values) != raw_count + 1:
        return INVALID_RESULT, b""
    stack = list(values[1:])
    if any(not -MAX_ABS_VALUE <= item <= MAX_ABS_VALUE for item in stack):
        return INVALID_RESULT, b""

    required = 8 * (raw_count + 1)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < required):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""

    encoded = (raw_count, *reversed(stack))
    output = b"".join(struct.pack("<q", value) for value in encoded)
    return len(output), output
