"""Oracle for the bounded AArch64 subStringEnd helper."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 128
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1
CHECKSUM_BASE = 1_100_000


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    start, text = values[0], values[1:]
    if not 0 <= start <= len(text) or len(text) > MAX_TEXT_LENGTH or any(not 1 <= byte <= 127 for byte in text):
        return INVALID_RESULT
    selected = text[start:]
    checksum = sum((index + 1) * byte for index, byte in enumerate(selected))
    return len(selected) * CHECKSUM_BASE + checksum
