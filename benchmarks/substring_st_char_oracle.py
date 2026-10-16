"""Oracle for the bounded AArch64 subStringStChar helper."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 128
MAX_REQUESTED_COUNT = 64
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1
CHECKSUM_BASE = 300_000


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    target, requested = values[:2]
    text = values[2:]
    if (not 1 <= target <= 127 or not 0 <= requested <= MAX_REQUESTED_COUNT
            or len(text) > MAX_TEXT_LENGTH or any(not 1 <= byte <= 127 for byte in text)):
        return INVALID_RESULT
    try:
        start = text.index(target)
    except ValueError:
        return INVALID_RESULT
    # The assembly copies the matching byte before checking the count.
    count = min(len(text) - start, max(1, requested))
    selected = text[start:start + count]
    checksum = sum((index + 1) * byte for index, byte in enumerate(selected))
    return count * CHECKSUM_BASE + checksum
