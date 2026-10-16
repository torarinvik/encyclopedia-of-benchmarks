"""Independent brute-force oracle for sorted-array pair existence."""

from __future__ import annotations

MAX_INPUT_LENGTH = 258


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    target, n = values[:2]
    array = values[2:]
    if not -2_000_000 <= target <= 2_000_000 or not 0 <= n <= 256:
        return -1
    if len(array) != n or any(not -1_000_000 <= value <= 1_000_000 for value in array):
        return -1
    if any(array[i] < array[i - 1] for i in range(1, n)):
        return -1

    return int(any(array[left] + array[right] == target
                   for left in range(n)
                   for right in range(left + 1, n)))
