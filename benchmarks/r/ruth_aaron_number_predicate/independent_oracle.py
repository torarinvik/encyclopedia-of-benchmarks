"""Least-prime-factor sieve reference, independent of trial division."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 100_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_FACTOR_SUM = MAX_N + 1
WORKSPACE_BYTES = 1_048_576
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values) or size != 1:
        return None
    n = values[0]
    return n if 1 <= n <= MAX_N else None


def _least_prime_factors(limit: int) -> list[int]:
    least = [0] * (limit + 1)
    for prime in range(2, limit + 1):
        if least[prime] != 0:
            continue
        least[prime] = prime
        multiple = prime * prime
        while multiple <= limit:
            if least[multiple] == 0:
                least[multiple] = prime
            multiple += prime
    return least


def _factor_sum_from_table(value: int, least: list[int]) -> int:
    total = 0
    while value > 1:
        prime = least[value]
        total += prime
        value //= prime
    return total


def _is_ruth_aaron(n: int) -> int:
    least = _least_prime_factors(n + 1)
    return int(_factor_sum_from_table(n, least) == _factor_sum_from_table(n + 1, least))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Build the least-prime-factor table once, then compare both sums."""
    n = _parse(values, input_is_null, input_length)
    return -1 if n is None else _is_ruth_aaron(n)
