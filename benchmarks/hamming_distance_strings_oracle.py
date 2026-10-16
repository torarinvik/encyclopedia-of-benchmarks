"""Oracle for Go's byte-indexed Hamming distance between equal-length strings."""

from __future__ import annotations

MAX_STRING_LENGTH = 128
MAX_INPUT_LENGTH = 2 + 2 * (MAX_STRING_LENGTH + 1)  # admit over-bound byte cases
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    left_length, right_length = values[:2]
    if (not 0 <= left_length <= MAX_STRING_LENGTH
            or not 0 <= right_length <= MAX_STRING_LENGTH
            or len(values) != 2 + left_length + right_length):
        return INVALID_RESULT
    left = values[2:2 + left_length]
    right = values[2 + left_length:]
    if any(not 0 <= byte <= 255 for byte in (*left, *right)):
        return INVALID_RESULT
    if left_length != right_length:
        return INVALID_RESULT
    return sum(a != b for a, b in zip(left, right))
