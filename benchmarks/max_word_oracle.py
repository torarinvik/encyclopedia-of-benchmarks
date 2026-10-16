"""Bounded byte reference for the pinned JavaScript maxWord routine."""

from __future__ import annotations

MAX_TEXT_LENGTH = 512
MAX_WORD_LENGTH = 6
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return the most frequent bounded word, or an ABI status."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    text_length = values[0]
    if not 1 <= text_length <= MAX_TEXT_LENGTH or len(values) != 1 + text_length:
        return INVALID_RESULT, b""
    text = values[1:]
    if any(not (value == 32 or 65 <= value <= 90 or 97 <= value <= 122)
           or value == 73 for value in text):
        return INVALID_RESULT, b""
    if text[0] == 32 or text[-1] == 32 or any(a == b == 32 for a, b in zip(text, text[1:])):
        return INVALID_RESULT, b""
    words = bytes(text).split(b" ")
    if any(not 1 <= len(word) <= MAX_WORD_LENGTH for word in words):
        return INVALID_RESULT, b""
    if len(words) == 1:
        result = words[0]
    else:
        counts: dict[bytes, int] = {}
        for word in words:
            key = word.lower()
            counts[key] = counts.get(key, 0) + 1
        winner = b""
        winner_count = 0
        for word, count in counts.items():
            if count > winner_count:
                winner = word
                winner_count = count
        result = winner
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < len(result):
            return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(result), result
