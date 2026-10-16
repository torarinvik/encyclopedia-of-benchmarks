"""Bounded oracle for the JavaScript second-largest-distinct-value scan."""

from __future__ import annotations

INVALID_RESULT = -(2**63)
MAX_ARRAY_LENGTH = 10_000
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 1
INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1


def expected_result(values: tuple[int, ...] | list[int]) -> int:
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT
    count, *items = values
    if (not 2 <= count <= MAX_ARRAY_LENGTH or len(items) != count
            or any(not INT32_MIN <= item <= INT32_MAX for item in items)):
        return INVALID_RESULT
    maximum = max(items)
    candidates = [item for item in items if item < maximum]
    return max(candidates) if candidates else INVALID_RESULT
