"""Reference first-match naive search on bounded ASCII byte strings."""

from __future__ import annotations

INVALID_RESULT = -2
NOT_FOUND = -1
MAX_LENGTH = 255
MAX_INPUT_LENGTH = 2 + 2 * MAX_LENGTH


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    text_length, pattern_length = values[:2]
    if (not 0 <= text_length <= MAX_LENGTH
            or not 0 <= pattern_length <= text_length
            or len(values) != 2 + text_length + pattern_length):
        return INVALID_RESULT
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(not 0 <= byte <= 127 for byte in text + pattern):
        return INVALID_RESULT
    if pattern_length == 0:
        return NOT_FOUND
    for start in range(text_length - pattern_length + 1):
        for offset, byte in enumerate(pattern):
            if text[start + offset] != byte:
                break
        else:
            return start
    return NOT_FOUND
