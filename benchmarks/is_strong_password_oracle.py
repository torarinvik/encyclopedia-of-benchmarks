"""Oracle for the bounded ASCII is_strong_password contract."""
from __future__ import annotations

MAX_TEXT_LENGTH = 256
MAX_INPUT_LENGTH = 258
INVALID_RESULT = -1
ASCII_PUNCTUATION = b"!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    min_length, text_length = values[0], values[1]
    if not 0 <= min_length <= MAX_TEXT_LENGTH or not 0 <= text_length <= MAX_TEXT_LENGTH:
        return INVALID_RESULT
    if len(values) != text_length + 2:
        return INVALID_RESULT
    text = values[2:]
    if any(not 0 <= byte <= 127 for byte in text):
        return INVALID_RESULT
    upper = any(65 <= byte <= 90 for byte in text)
    lower = any(97 <= byte <= 122 for byte in text)
    digit = any(48 <= byte <= 57 for byte in text)
    punctuation = any(byte in ASCII_PUNCTUATION for byte in text)
    return int(text_length >= min_length and upper and lower and digit and punctuation)
