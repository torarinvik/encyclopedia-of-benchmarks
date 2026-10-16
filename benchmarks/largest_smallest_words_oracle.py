"""Bounded byte reference for the pinned Python smallest/largest word routine."""

from __future__ import annotations

import struct

MAX_TEXT_LENGTH = 512
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 3
MAX_OUTPUT_BYTES = 2 * MAX_TEXT_LENGTH + 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
STRIP_BYTES = b".,!?()[]{}"


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return a length-prefixed (smallest, largest) pair, or an ABI status."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    text_length = values[0]
    if not 1 <= text_length <= MAX_TEXT_LENGTH or len(values) != 1 + text_length:
        return INVALID_RESULT, b""
    text = values[1:]
    if any(not 32 <= value <= 126 for value in text):
        return INVALID_RESULT, b""
    words = [word.strip(STRIP_BYTES) for word in bytes(text).split(b" ") if word]
    if not words:
        return INVALID_RESULT, b""
    smallest = min(words, key=len)
    largest = max(words, key=len)
    output = struct.pack("<I", len(smallest)) + smallest + struct.pack("<I", len(largest)) + largest
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < len(output):
            return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
