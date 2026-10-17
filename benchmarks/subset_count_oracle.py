"""Oracle for the bounded Java getCountSO subset-count recurrence."""
from __future__ import annotations

from collections.abc import Sequence

MAX_COUNT = 30
MAX_TARGET = 64
MAX_VALUE = 64
MAX_INPUT_VALUES = MAX_COUNT + 3
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_VALUES
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    count, target = values[0], values[1]
    if not 1 <= count <= MAX_COUNT or not 0 <= target <= MAX_TARGET or len(values) != count + 2:
        return INVALID_RESULT
    items = values[2:]
    if any(not 0 <= value <= MAX_VALUE for value in items):
        return INVALID_RESULT

    previous = [0] * (target + 1)
    previous[0] = 1
    if items[0] <= target:
        previous[items[0]] = 1

    for value in items[1:]:
        current = [0] * (target + 1)
        current[0] = 1
        for amount in range(1, target + 1):
            not_taken = previous[amount]
            taken = previous[amount - value] if value <= amount else 0
            current[amount] = not_taken + taken
        previous = current
    return previous[target]
