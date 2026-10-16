"""Independent memoized reference for counting a bounded digit sum."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MAX_DIGITS = 19
MAX_DIGIT_SUM = 9 * MAX_DIGITS
MAX_BOUND = 1_000_000_000_000_000_000
MIN_BOUND = -1
MAX_INPUT_LENGTH = 3
I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
INVALID_RESULT = -1


def _count_up_to(bound: int, target: int) -> int:
    if bound < 0:
        return 0
    digits = tuple(int(character) for character in str(bound))

    @lru_cache(maxsize=None)
    def solve(index: int, current_sum: int, tight: bool) -> int:
        if index == len(digits):
            return int(current_sum == target)
        limit = digits[index] if tight else 9
        count = 0
        for digit in range(min(limit, target - current_sum) + 1):
            count += solve(index + 1, current_sum + digit, tight and digit == limit)
        return count

    return solve(0, 0, True)


def expected_result(values: Sequence[int]) -> int:
    """Count values in the bounded inclusive range with the requested digit sum."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH + 1
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    if len(values) != 3:
        return INVALID_RESULT
    lower, upper, target = values
    if (not MIN_BOUND <= lower <= MAX_BOUND or not MIN_BOUND <= upper <= MAX_BOUND
            or not I32_MIN <= target <= I32_MAX):
        return INVALID_RESULT
    if lower > upper or target < 0 or target > MAX_DIGIT_SUM:
        return 0
    return _count_up_to(upper, target) - _count_up_to(lower - 1, target)
