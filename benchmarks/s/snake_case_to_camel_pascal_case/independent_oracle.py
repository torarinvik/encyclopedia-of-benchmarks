"""Independent split-and-join reference for snake_case capitalization."""

from __future__ import annotations

from typing import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    INVALID_RESULT,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_STRING_LENGTH,
    OUTPUT_ERROR_RESULT,
)


def expected_output(
        values: Sequence[int] | None,
        capacity: int | None = None,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None) -> tuple[int, bytes]:
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

    mode, codepoints = values[0], values[1:]
    if (mode not in (0, 1) or not 1 <= len(codepoints) <= MAX_STRING_LENGTH
            or any(not (97 <= value <= 122 or 48 <= value <= 57 or value == 95)
                   for value in codepoints)):
        return INVALID_RESULT, b""
    text = bytes(codepoints)
    if text.startswith(b"_") or text.endswith(b"_") or b"__" in text:
        return INVALID_RESULT, b""

    words = [word for word in text.split(b"_")]
    transformed = []
    for index, word in enumerate(words):
        should_capitalize = mode == 1 or index > 0
        if should_capitalize and 97 <= word[0] <= 122:
            transformed.append(bytes((word[0] - 32,)) + word[1:])
        else:
            transformed.append(word)
    encoded = b"".join(transformed)
    if output_is_null or actual_capacity < len(encoded):
        return OUTPUT_ERROR_RESULT, b""
    return len(encoded), encoded
