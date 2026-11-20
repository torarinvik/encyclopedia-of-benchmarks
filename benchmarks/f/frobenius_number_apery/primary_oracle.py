"""Residue shortest-path reference for bounded Frobenius numbers."""

from __future__ import annotations

from collections.abc import Sequence

MAX_DENOMINATIONS = 4
MAX_DENOMINATION = 16
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_VALID_INPUT_LENGTH = 5
MAX_SEARCH_BOUND = 224
MAX_FROBENIUS_NUMBER = 209
MAX_RESULT_BOUND = MAX_FROBENIUS_NUMBER
MAX_RESULT = MAX_FROBENIUS_NUMBER
WORKSPACE_BYTES = 256
INVALID_RESULT = -1


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
            or len(values) < 3 or len(values) > MAX_VALID_INPUT_LENGTH):
        return None
    count = values[0]
    if not 2 <= count <= MAX_DENOMINATIONS or len(values) != count + 1:
        return None
    coins = tuple(values[1:])
    if (any(not 2 <= coin <= MAX_DENOMINATION for coin in coins)
            or len(set(coins)) != count):
        return None
    common = 0
    for coin in coins:
        common = _gcd(common, coin)
    return coins if common == 1 else None


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def _apery_frobenius(coins: tuple[int, ...]) -> int:
    modulus = min(coins)
    distance: list[int | None] = [None] * modulus
    settled = [False] * modulus
    distance[0] = 0
    for _ in range(modulus):
        source = -1
        best: int | None = None
        for residue, value in enumerate(distance):
            if not settled[residue] and value is not None and (best is None or value < best):
                source = residue
                best = value
        if source < 0 or best is None:
            return INVALID_RESULT
        settled[source] = True
        for coin in coins:
            target = (source + coin) % modulus
            candidate = best + coin
            if distance[target] is None or candidate < distance[target]:
                distance[target] = candidate
    if any(value is None for value in distance):
        return INVALID_RESULT
    return max(value for value in distance if value is not None) - modulus


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the largest nonnegative nonrepresentable amount, or -1."""
    coins = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if coins is None else _apery_frobenius(coins)
