"""Independent oracle for the bounded Go coinchange contract."""

from __future__ import annotations

from functools import lru_cache

MAX_AMOUNT = 30
MAX_COINS = 8
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    """Count combinations for amount - 1, treating duplicate types separately."""
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_COINS + 2
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    amount, coin_count = values[:2]
    if not 1 <= amount <= MAX_AMOUNT or not 0 <= coin_count <= MAX_COINS:
        return INVALID_RESULT
    if len(values) != coin_count + 2:
        return INVALID_RESULT
    coins = values[2:]
    if any(not 1 <= coin <= MAX_AMOUNT for coin in coins):
        return INVALID_RESULT

    target = amount - 1

    @lru_cache(maxsize=None)
    def count_types(index: int, remaining: int) -> int:
        if index == len(coins):
            return int(remaining == 0)
        coin = coins[index]
        return sum(
            count_types(index + 1, remaining - copies * coin)
            for copies in range(remaining // coin + 1)
        )

    return count_types(0, target)
