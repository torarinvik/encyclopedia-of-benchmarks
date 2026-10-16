"""Reference for the pinned Java hexadecimal-string to int conversion."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_ASCII_VALUE = 127
INVALID_RESULT = -(1 << 31) - 1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
UINT32_MASK = (1 << 32) - 1
I32_MAX = (1 << 31) - 1


def expected_result(values: Sequence[int]) -> int:
    """Parse ASCII hexadecimal characters and preserve Java signed-int wrap."""
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    if len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT

    accumulator = 0
    for code in values:
        if not 0 <= code <= MAX_ASCII_VALUE:
            return INVALID_RESULT
        if 48 <= code <= 57:
            digit = code - 48
        elif 65 <= code <= 70:
            digit = code - 55
        elif 97 <= code <= 102:
            digit = code - 87
        else:
            return INVALID_RESULT
        accumulator = (accumulator * 16 + digit) & UINT32_MASK

    return accumulator if accumulator <= I32_MAX else accumulator - (1 << 32)
