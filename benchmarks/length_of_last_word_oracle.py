"""Oracle for Java LengthOfLastWord over a bounded byte-string domain."""

from __future__ import annotations

MAX_BYTES = 128
MAX_INPUT_LENGTH = MAX_BYTES + 1
INVALID_RESULT = -1

def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    byte_length = values[0]
    if not 0 <= byte_length <= MAX_BYTES or len(values) != byte_length + 1:
        return INVALID_RESULT
    text = values[1:]
    if any(not 0 <= byte <= 255 for byte in text):
        return INVALID_RESULT
    index = byte_length - 1
    while index >= 0 and text[index] == 32:
        index -= 1
    end = index
    while index >= 0 and text[index] != 32:
        index -= 1
    return end - index
