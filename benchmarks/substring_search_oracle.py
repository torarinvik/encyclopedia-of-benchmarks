"""Oracle for the pinned AArch64 searchSubString helper's bounded byte behavior."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 128
MAX_PATTERN_LENGTH = 64
MAX_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -2
NOT_FOUND_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    text_length, pattern_length = values[:2]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or not 0 <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_length + pattern_length):
        return INVALID_RESULT
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(not 1 <= byte <= 127 for byte in (*text, *pattern)):
        return INVALID_RESULT

    # The assembly advances past a mismatching text byte instead of retrying it
    # as the start of a new candidate. That intentionally misses overlaps.
    text_index = 0
    pattern_index = 0
    match_start = -1
    while text_index < text_length:
        expected_byte = pattern[pattern_index] if pattern_index < pattern_length else 0
        if text[text_index] == expected_byte:
            if match_start == -1:
                match_start = text_index
            pattern_index += 1
            if pattern_index == pattern_length:
                return match_start
            text_index += 1
        else:
            match_start = -1
            pattern_index = 0
            text_index += 1
    return NOT_FOUND_RESULT
