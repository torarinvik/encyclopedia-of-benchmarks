"""Independent contract oracle for the byte-string Hamming distance ABI."""

from __future__ import annotations

MAX_BYTE_LENGTH = 1024
MAX_INPUT_LENGTH = 2050


def expected_result(values: list[int]) -> int:
    """Return mismatching byte positions, or -1 for a malformed packed input."""
    if not values or len(values) > MAX_INPUT_LENGTH:
        return -1
    count = values[0]
    if type(count) is not int or not 0 <= count <= MAX_BYTE_LENGTH:
        return -1
    if len(values) != 1 + 2 * count:
        return -1
    left = values[1 : 1 + count]
    right = values[1 + count :]
    if any(type(byte) is not int or not 0 <= byte <= 255 for byte in left + right):
        return -1
    return sum(first != second for first, second in zip(left, right))
