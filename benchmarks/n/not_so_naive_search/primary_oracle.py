"""Primary two-shift reference for the Not So Naive matcher."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 512
MAX_PATTERN_LENGTH = 64
MIN_PATTERN_LENGTH = 2
MAX_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
INVALID_RESULT = -2
NOT_FOUND = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Find the first byte offset with the prescribed two-shift scan."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    if length is None:
        declared = len(values) if isinstance(values, (tuple, list)) else -1
    elif type(length) is int and length >= 0:
        declared = length
    else:
        return INVALID_RESULT
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or declared != len(values)):
        return INVALID_RESULT
    text_length, pattern_length = values[:2]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or not MIN_PATTERN_LENGTH <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_length + pattern_length):
        return INVALID_RESULT
    text_start = 2
    pattern_start = text_start + text_length
    if any(not 0 <= byte <= 127 for byte in values[text_start:]):
        return INVALID_RESULT
    if pattern_length > text_length:
        return NOT_FOUND

    same_prefix = values[pattern_start] == values[pattern_start + 1]
    mismatch_shift, post_check_shift = (2, 1) if same_prefix else (1, 2)
    position = 0
    while position <= text_length - pattern_length:
        if values[pattern_start + 1] != values[text_start + position + 1]:
            position += mismatch_shift
            continue
        pattern_index = 2
        while (pattern_index < pattern_length
               and values[pattern_start + pattern_index]
               == values[text_start + position + pattern_index]):
            pattern_index += 1
        if (pattern_index == pattern_length
                and values[pattern_start] == values[text_start + position]):
            return position
        position += post_check_shift
    return NOT_FOUND
