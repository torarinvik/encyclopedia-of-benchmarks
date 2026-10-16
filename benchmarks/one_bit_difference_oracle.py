"""Oracle for Java's one-bit-difference predicate over signed 32-bit values."""

from __future__ import annotations

INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1
MAX_INPUT_LENGTH = 3  # one extra slot allows an invalid arity case through the parser


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not INT32_MIN <= value <= INT32_MAX
                   for value in values)):
        return -1
    left, right = values
    difference = (left ^ right) & 0xFFFFFFFF
    return int(left != right and difference & (difference - 1) == 0)
