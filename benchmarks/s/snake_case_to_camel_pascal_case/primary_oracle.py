"""Source-shaped reference for bounded snake_case capitalization."""

from __future__ import annotations

from typing import Sequence

MAX_STRING_LENGTH = 256
MAX_VALID_INPUT_LENGTH = MAX_STRING_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_STRING_LENGTH + 2
MAX_OUTPUT_BYTES = MAX_STRING_LENGTH
WORKSPACE_BYTES = MAX_OUTPUT_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
        values: Sequence[int] | None,
        capacity: int | None = None,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None) -> tuple[int, bytes]:
    """Transform ASCII words after validating the complete ABI frame."""
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(actual_capacity) is not int or actual_capacity < 0
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    if input_is_null:
        if values not in (None, (), []) or input_length is None:
            return INVALID_RESULT, b""
        return INVALID_RESULT, b""
    if (not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or input_length is not None and input_length != len(values)
            or len(values) < 2):
        return INVALID_RESULT, b""

    mode, raw = values[0], values[1:]
    if (mode not in (0, 1) or not 1 <= len(raw) <= MAX_STRING_LENGTH
            or any(not (97 <= value <= 122 or 48 <= value <= 57 or value == 95)
                   for value in raw)
            or raw[0] == 95 or raw[-1] == 95
            or any(left == right == 95 for left, right in zip(raw, raw[1:]))):
        return INVALID_RESULT, b""

    output = bytearray()
    capitalize_next = mode == 1
    for value in raw:
        if value == 95:
            capitalize_next = True
        elif capitalize_next and 97 <= value <= 122:
            output.append(value - 32)
            capitalize_next = False
        else:
            output.append(value)
            capitalize_next = False
    encoded = bytes(output)
    if output_is_null or actual_capacity < len(encoded):
        return OUTPUT_ERROR_RESULT, b""
    return len(encoded), encoded
