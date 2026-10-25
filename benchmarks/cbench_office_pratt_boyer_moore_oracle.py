"""Independent scalar model for cBench's bounded Pratt-Boyer-Moore helper."""
from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 255
MIN_PATTERN_LENGTH = 1
MAX_PATTERN_LENGTH = 64
MAX_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
INVALID_RESULT = -2
NOT_FOUND = -1


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID_RESULT
    text_length, pattern_length = values[:2]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or not MIN_PATTERN_LENGTH <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_length + pattern_length):
        return INVALID_RESULT
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(not 1 <= byte <= 127 for byte in text + pattern):
        return INVALID_RESULT

    shifts = [pattern_length] * 128
    for index, byte in enumerate(pattern):
        shifts[byte] = pattern_length - index - 1

    # Preserve the pinned helper's endpoint scan: a zero shift means the
    # window-ending byte matches the pattern's last byte; then compare all
    # bytes and advance exactly one if that endpoint was a false positive.
    position = pattern_length - 1
    while position < text_length:
        shift = shifts[text[position]]
        while position < text_length and shift > 0:
            position += shift
            if position < text_length:
                shift = shifts[text[position]]
        if position < text_length and shift == 0:
            start = position - pattern_length + 1
            if text[start:start + pattern_length] == pattern:
                return start
            position += 1
    return NOT_FOUND
