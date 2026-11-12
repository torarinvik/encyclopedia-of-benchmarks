"""Segmented direct-factorization oracle for bounded multiplicative-function cases."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

MODULUS = 469_762_049
MAX_N = 100_000_000
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1
ORACLE_BLOCK_SIZE = 32_768


def _smallest_prime_sieve(limit: int) -> list[int]:
    smallest = list(range(limit + 1))
    if limit >= 1:
        smallest[1] = 1
    for value in range(2, isqrt(limit) + 1):
        if smallest[value] == value:
            for multiple in range(value * value, limit + 1, value):
                if smallest[multiple] == multiple:
                    smallest[multiple] = value
    return smallest


def _direct_sum(n: int, a: int, b: int) -> int:
    if a == 0 and b == 0:
        return 1
    smallest = _smallest_prime_sieve(isqrt(n))
    primes = [value for value in range(2, len(smallest)) if smallest[value] == value]
    total = 0
    for start in range(1, n + 1, ORACLE_BLOCK_SIZE):
        end = min(n, start + ORACLE_BLOCK_SIZE - 1)
        remaining = list(range(start, end + 1))
        values = [1] * len(remaining)
        for prime in primes:
            if prime > end:
                break
            first_multiple = ((start + prime - 1) // prime) * prime
            for multiple in range(first_multiple, end + 1, prime):
                index = multiple - start
                exponent = 0
                while remaining[index] % prime == 0:
                    remaining[index] //= prime
                    exponent += 1
                if exponent:
                    local_value = (a * exponent + b * prime) % MODULUS
                    values[index] = values[index] * local_value % MODULUS
        for index, factor in enumerate(remaining):
            if factor > 1:
                values[index] = values[index] * (a + b * factor) % MODULUS
        total = (total + sum(values)) % MODULUS
    return total


def expected_result(values: Sequence[int] | None) -> int:
    """Return the summatory value, or -1 for malformed or out-of-contract input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT
    n, a, b = values
    if not 1 <= n <= MAX_N or not 0 <= a < MODULUS or not 0 <= b < MODULUS:
        return INVALID_RESULT
    return _direct_sum(n, a, b)
