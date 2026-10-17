"""Bounded reference for the chunked decimal prefix sum in Problem 13."""

from __future__ import annotations

MAX_INPUT_BYTES = 5000
MAX_INPUT_VALUES = MAX_INPUT_BYTES + 1
MAX_OUTPUT_BYTES = 10
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the source-compatible decimal prefix length and ASCII bytes."""
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_VALUES:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    byte_length = values[0]
    if not 1 <= byte_length <= MAX_INPUT_BYTES or len(values) != byte_length + 1:
        return INVALID_RESULT, b""
    if any(not 48 <= value <= 57 for value in values[1:]):
        return INVALID_RESULT, b""

    # The JavaScript source uses the first chunk's width for every chunk. A
    # shorter final chunk is left-aligned; missing charAt positions add zero.
    width = min(byte_length, 50)
    reversed_digits: list[int] = []
    carry = 0
    for position in range(width - 1, -1, -1):
        column = carry
        for start in range(0, byte_length, 50):
            chunk_length = min(50, byte_length - start)
            if position < chunk_length:
                column += values[1 + start + position] - 48
        reversed_digits.append(column % 10)
        carry = column // 10

    while carry:
        reversed_digits.append(carry % 10)
        carry //= 10

    output_length = min(MAX_OUTPUT_BYTES, len(reversed_digits))
    output = bytes(48 + reversed_digits[-1 - index] for index in range(output_length))
    return output_length, output
