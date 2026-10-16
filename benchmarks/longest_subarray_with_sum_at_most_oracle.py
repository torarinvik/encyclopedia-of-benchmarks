"""Independent oracle for the bounded nonnegative sliding-window benchmark."""

from __future__ import annotations

MAX_ARRAY_LENGTH = 256
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 3
MAX_DOMAIN_VALUE = 2**31 - 1
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (
        not isinstance(values, list)
        or not 2 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1 for value in values)
    ):
        return INVALID_RESULT

    target, raw_count = values[:2]
    if (
        not 0 <= target <= MAX_DOMAIN_VALUE
        or not 0 <= raw_count <= MAX_ARRAY_LENGTH
        or len(values) != raw_count + 2
    ):
        return INVALID_RESULT

    items = values[2:]
    if any(not 0 <= value <= MAX_DOMAIN_VALUE for value in items):
        return INVALID_RESULT

    left = 0
    window_sum = 0
    longest = 0
    for right, value in enumerate(items):
        window_sum += value
        while window_sum > target and left <= right:
            window_sum -= items[left]
            left += 1
        longest = max(longest, right - left + 1)
    return longest
