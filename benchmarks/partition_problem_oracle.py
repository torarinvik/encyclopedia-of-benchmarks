"""Independent brute-force oracle for equal-sum partition."""

from __future__ import annotations

MAX_ITEMS = 16
MAX_ITEM = 256
MAX_TOTAL = 1024


def expected_result(values: list[int]) -> int:
    if not 1 <= len(values) <= MAX_ITEMS:
        return -1
    if any(type(value) is not int or not 0 <= value <= MAX_ITEM for value in values):
        return -1
    total = sum(values)
    if total > MAX_TOTAL:
        return -1
    if total % 2:
        return 0
    target = total // 2
    for mask in range(1 << len(values)):
        subset_sum = sum(value for index, value in enumerate(values) if mask & (1 << index))
        if subset_sum == target:
            return 1
    return 0
