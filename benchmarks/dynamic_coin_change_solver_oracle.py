"""Bounded oracle for the C# backward-induction coin sequence solver."""

from __future__ import annotations

INVALID_RESULT = -1
MAX_AMOUNT = 18
MAX_DENOMINATION = 9
MAX_COINS = 9


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_COINS + 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    amount, count = values[:2]
    coins = list(values[2:])
    if (not 1 <= amount <= MAX_AMOUNT or not 1 <= count <= MAX_COINS
            or len(coins) != count or any(not 1 <= coin <= MAX_DENOMINATION for coin in coins)
            or len(set(coins)) != count or 1 not in coins):
        return INVALID_RESULT
    ordered = sorted(coins, reverse=True)
    changes: list[list[int]] = [[] for _ in range(amount + 1)]
    for current in range(1, amount + 1):
        changes[current] = [current - coin for coin in ordered if coin <= current]

    def minimal_next(current: int) -> int:
        next_coin = (1 << 31) - 1
        minimum_change = (1 << 31) - 1
        for change in changes[current]:
            if change == 0:
                return 0
            current_minimum = min(changes[change])
            if current_minimum < minimum_change:
                next_coin = change
                minimum_change = current_minimum
        return next_coin

    sequence: list[int] = []
    current = amount
    while True:
        remaining = minimal_next(current)
        if remaining == (1 << 31) - 1:
            return INVALID_RESULT
        sequence.append(current - remaining)
        if remaining == 0:
            break
        current = remaining
    code = 0
    for coin in sequence:
        code = code * 10 + coin
    return code
