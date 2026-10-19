"""Reference model for MiBench's bounded case-sensitive BMH search stage."""
from __future__ import annotations

import struct

MAX_TEXT_LENGTH = 128
MAX_PATTERN_LENGTH = 32
MAX_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
OUTPUT_BYTES = 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the first exact byte match as one little-endian i64 offset."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values) or len(values) < 2):
        return INVALID_RESULT, b""
    text_length, pattern_length = values[0], values[1]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or not 1 <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_length + pattern_length):
        return INVALID_RESULT, b""
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(not 32 <= byte <= 126 for byte in (*text, *pattern)):
        return INVALID_RESULT, b""
    position = -1
    for candidate in range(max(0, text_length - pattern_length + 1)):
        if tuple(text[candidate:candidate + pattern_length]) == tuple(pattern):
            position = candidate
            break
    return OUTPUT_BYTES, struct.pack("<q", position)
