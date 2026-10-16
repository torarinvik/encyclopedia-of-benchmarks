"""Independent oracle for the bounded burst-balloons benchmark."""

from __future__ import annotations

from functools import lru_cache

MAX_BALLOONS = 128
MAX_VALUE = 1000
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    """Return the maximum burst score, or -1 for an out-of-contract array."""
    if (not isinstance(values, list) or len(values) > MAX_BALLOONS
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    if any(value < 0 or value > MAX_VALUE for value in values):
        return INVALID_RESULT
    if not values:
        return 0

    padded = (1, *values, 1)

    @lru_cache(maxsize=None)
    def best(left: int, right: int) -> int:
        if left > right:
            return 0
        return max(
            best(left, last - 1)
            + best(last + 1, right)
            + padded[left - 1] * padded[last] * padded[right + 1]
            for last in range(left, right + 1)
        )

    return best(1, len(values))
