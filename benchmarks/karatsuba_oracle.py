"""Exact oracle for the bounded Karatsuba multiplication workload."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_OPERAND = 1_000_000
MAX_INPUT_LENGTH = 3


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    left, right = values
    if not 0 <= left <= MAX_OPERAND or not 0 <= right <= MAX_OPERAND:
        return -1
    return left * right
