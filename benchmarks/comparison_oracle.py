"""Oracle for bounded case-sensitive and ASCII-insensitive string comparison."""

from __future__ import annotations

MAX_STRING_LENGTH = 64
MAX_INPUT_LENGTH = 3 + 2 * MAX_STRING_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _fold_ascii(value: int, mode: int) -> int:
    if mode == 1 and ord("A") <= value <= ord("Z"):
        return value + (ord("a") - ord("A"))
    return value


def expected_result(values: tuple[int, ...] | list[int]) -> int:
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -2
    mode, first_length_value = values[0], values[1]
    if mode not in (0, 1) or not 0 <= first_length_value <= MAX_STRING_LENGTH:
        return -2
    first_length = first_length_value
    second_length_position = 2 + first_length
    if second_length_position >= len(values):
        return -2
    second_length_value = values[second_length_position]
    if not 0 <= second_length_value <= MAX_STRING_LENGTH:
        return -2
    second_length = second_length_value
    second_start = second_length_position + 1
    if second_start + second_length != len(values):
        return -2
    first = values[2:second_length_position]
    second = values[second_start:]
    if any(byte < 1 or byte > 127 for byte in first + second):
        return -2

    for left, right in zip(first, second):
        left = _fold_ascii(left, mode)
        right = _fold_ascii(right, mode)
        if left < right:
            return -1
        if left > right:
            return 1
    if first_length < second_length:
        return -1
    if first_length > second_length:
        return 1
    return 0
