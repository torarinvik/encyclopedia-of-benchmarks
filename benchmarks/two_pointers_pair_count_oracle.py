"""Independent oracle for the PHP two-pointer complementary-pair count."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALUES = 256
MAX_INPUT_LENGTH = MAX_VALUES + 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1

    target, count = values[:2]
    items = values[2:]
    if (not -2_000_000 <= target <= 2_000_000 or not 0 <= count <= MAX_VALUES
            or len(items) != count
            or any(not -1_000_000 <= value <= 1_000_000 for value in items)
            or len(set(items)) != count):
        return -1

    # Distinct values make each matching index pair disjoint from every other match.
    return sum(items[left] + items[right] == target
               for left in range(count)
               for right in range(left + 1, count))

