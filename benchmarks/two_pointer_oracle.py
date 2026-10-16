"""Oracle for sorted-array two-sum via two moving endpoints."""

from __future__ import annotations

MAX_COUNT = 256
MAX_INPUT_LENGTH = MAX_COUNT + 2
I32_MIN = -(2**31)
I32_MAX = 2**31 - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -2
    count, target = values[:2]
    items = values[2:]
    if (not 0 <= count <= MAX_COUNT or len(items) != count
            or not I32_MIN <= target <= I32_MAX
            or any(not I32_MIN <= item <= I32_MAX for item in items)
            or any(left > right for left, right in zip(items, items[1:]))):
        return -2
    left, right = 0, count - 1
    while left < right:
        total = items[left] + items[right]
        if total == target:
            return left * 256 + right
        if total < target:
            left += 1
        else:
            right -= 1
    return -1
