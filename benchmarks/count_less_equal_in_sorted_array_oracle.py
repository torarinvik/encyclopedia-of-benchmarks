"""Independent oracle for the bounded Java count-less-or-equal search."""

from __future__ import annotations

MAX_VALUES = 512
MAX_INPUT_LENGTH = MAX_VALUES + 2  # key, plus one over-bound array element
INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1


def expected_result(input_values: list[int]) -> int:
    """Return the first index after all sorted values <= key, or -1 if invalid."""
    if (not isinstance(input_values, list) or not 1 <= len(input_values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in input_values)):
        return -1

    key, values = input_values[0], input_values[1:]
    if (len(values) > MAX_VALUES or not INT32_MIN <= key <= INT32_MAX
            or any(not INT32_MIN <= value <= INT32_MAX for value in values)
            or any(left > right for left, right in zip(values, values[1:]))):
        return -1

    low, high, count = 0, len(values) - 1, 0
    while low <= high:
        middle = low + (high - low) // 2
        if values[middle] > key:
            high = middle - 1
        else:
            count = middle + 1
            low = middle + 1
    return count
