"""Oracle for the bounded ASCII adaptation of AArch64 subStringNbChar."""

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
    """Encode the copied byte string as length*base plus positional checksum."""
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    start, requested_count = values[:2]
    text = values[2:]
    if (not 0 <= start <= len(text) or not 0 <= requested_count <= MAX_REQUESTED_COUNT
            or len(text) > MAX_TEXT_LENGTH or any(not 1 <= byte <= 127 for byte in text)):
        return INVALID_RESULT

    # The assembly copies before checking whether its counter has reached x3.
    # Therefore a zero requested count copies one byte when one is available.
    actual_count = min(len(text) - start, max(1, requested_count))
    selected = text[start:start + actual_count]
    checksum = sum((index + 1) * byte for index, byte in enumerate(selected))
    return actual_count * CHECKSUM_BASE + checksum
