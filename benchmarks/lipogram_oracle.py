"""Independent scalar oracle for the bounded ASCII lipogram contract."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_TEXT_BYTES = 1024
MAX_MISSING_MASK = (1 << 26) - 1
INVALID_RESULT = -1
ASCII_WHITESPACE = {9, 10, 11, 12, 13, 32}


def expected_result(values: list[int]) -> int:
    """Return whether the text omits exactly the lowercase letters in its mask."""
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_TEXT_BYTES + 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    text_length = values[0]
    if not 0 <= text_length <= MAX_TEXT_BYTES or len(values) != text_length + 2:
        return INVALID_RESULT
    text = values[1:1 + text_length]
    missing_mask = values[-1]
    if not 0 <= missing_mask <= MAX_MISSING_MASK:
        return INVALID_RESULT

    used: set[int] = set()
    for byte in text:
        if 65 <= byte <= 90:
            used.add(byte + 32)
        elif 97 <= byte <= 122:
            used.add(byte)
        elif byte not in ASCII_WHITESPACE:
            return INVALID_RESULT

    missing = {letter for letter in range(ord("a"), ord("z") + 1) if letter not in used}
    expected = {ord("a") + bit for bit in range(26) if missing_mask & (1 << bit)}
    return int(missing == expected)
