"""Reference output for the longest consecutive ASCII-character run."""

from __future__ import annotations

MAX_INPUT_LENGTH = 257
MAX_STRING_LENGTH = 256
OUTPUT_BYTES = 3


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    length = values[0]
    if not 1 <= length <= MAX_STRING_LENGTH or len(values) != length + 1:
        return -1, b""
    characters = values[1:]
    if any(not 0 <= character <= 127 for character in characters):
        return -1, b""

    best_character = characters[0]
    best_length = current_length = 1
    for index in range(1, length):
        if characters[index] == characters[index - 1]:
            current_length += 1
            if current_length > best_length:
                best_length = current_length
                best_character = characters[index]
        else:
            current_length = 1
    output = bytes((best_character, best_length & 0xFF, best_length >> 8))
    return OUTPUT_BYTES, output
