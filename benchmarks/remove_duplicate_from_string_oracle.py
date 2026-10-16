"""Bounded byte reference for the pinned Java duplicate-character remover."""

from __future__ import annotations

MAX_TEXT_LENGTH = 512
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return unique ASCII bytes in first-occurrence order, or an ABI status."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    text_length = values[0]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or len(values) != 1 + text_length):
        return INVALID_RESULT, b""
    text = values[1:]
    if any(not 0 <= value <= 127 for value in text):
        return INVALID_RESULT, b""
    seen = bytearray(128)
    output = bytearray()
    for value in text:
        if not seen[value]:
            seen[value] = 1
            output.append(value)
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < len(output):
            return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), bytes(output)
