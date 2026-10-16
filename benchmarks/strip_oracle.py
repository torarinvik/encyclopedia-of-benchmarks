"""Bounded ASCII contract for TheAlgorithms/Python's character strip."""

from __future__ import annotations

MAX_TEXT_LENGTH = 256
MAX_CHARACTER_LENGTH = 128
MAX_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_CHARACTER_LENGTH
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
DEFAULT_CHARACTERS = frozenset((9, 10, 13, 32))


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the stripped ASCII bytes, retaining the source's end-only scan."""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT, b""

    text_length = values[0]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or len(values) < text_length + 2:
        return INVALID_RESULT, b""
    text_start = 1
    text_end = text_start + text_length
    text = values[text_start:text_end]
    character_length = values[text_end]
    if character_length == -1:
        if len(values) != text_end + 1:
            return INVALID_RESULT, b""
        characters = DEFAULT_CHARACTERS
    else:
        if (not 0 <= character_length <= MAX_CHARACTER_LENGTH
                or len(values) != text_end + 1 + character_length):
            return INVALID_RESULT, b""
        character_values = values[text_end + 1:]
        if any(not 0 <= value <= 127 for value in character_values):
            return INVALID_RESULT, b""
        characters = frozenset(character_values)

    if any(not 0 <= value <= 127 for value in text):
        return INVALID_RESULT, b""
    start, end = 0, text_length
    while start < end and text[start] in characters:
        start += 1
    while end > start and text[end - 1] in characters:
        end -= 1
    output = bytes(text[start:end])
    return len(output), output
