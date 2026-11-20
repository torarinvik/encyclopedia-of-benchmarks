"""Boolean reachability-DP reference for bounded Frobenius numbers."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_DENOMINATIONS,
    MAX_DENOMINATION,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_SEARCH_BOUND,
    MAX_VALID_INPUT_LENGTH,
    _gcd,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or not 3 <= len(values) <= MAX_VALID_INPUT_LENGTH):
        return None
    count = values[0]
    if not 2 <= count <= MAX_DENOMINATIONS or len(values) != count + 1:
        return None
    coins = tuple(values[1:])
    if (any(coin < 2 or coin > MAX_DENOMINATION for coin in coins)
            or len(set(coins)) != count):
        return None
    common = 0
    for coin in coins:
        common = _gcd(common, coin)
    return coins if common == 1 else None


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the largest gap by scanning bounded representability states."""
    coins = _parse(values, input_is_null, input_length)
    if coins is None:
        return INVALID_RESULT
    reachable = [False] * (MAX_SEARCH_BOUND + 1)
    reachable[0] = True
    for amount in range(1, MAX_SEARCH_BOUND + 1):
        reachable[amount] = any(
            amount >= coin and reachable[amount - coin] for coin in coins
        )
    # The residue-path bound guarantees every amount >=224 is representable,
    # so the final nonreachable state in the table is the Frobenius number.
    return max(amount for amount, is_reachable in enumerate(reachable[:-1])
               if not is_reachable)
