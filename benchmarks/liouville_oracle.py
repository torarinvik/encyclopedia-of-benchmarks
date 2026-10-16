"""Independent oracle for Go's distinct-prime-factor parity function."""

from __future__ import annotations

from functools import lru_cache
import math

MIN_INPUT = 1
MAX_INPUT = 2_147_483_647
INVALID_RESULT = -2


@lru_cache(maxsize=1)
def primes_through_sqrt_bound() -> tuple[int, ...]:
    """Sieve primes through sqrt(MAX_INPUT) for a distinct-factor count."""
    limit = math.isqrt(MAX_INPUT)
    is_prime = bytearray(b"\x01") * (limit + 1)
    is_prime[0:2] = b"\x00\x00"
    for value in range(2, math.isqrt(limit) + 1):
        if is_prime[value]:
            is_prime[value * value : limit + 1 : value] = b"\x00" * (
                (limit - value * value) // value + 1
            )
    return tuple(value for value, flag in enumerate(is_prime) if flag)


def expected_result(value: int) -> int:
    """Return (-1)^omega(value), or the adapter sentinel outside the domain."""
    if type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT:
        return INVALID_RESULT
    remaining = value
    distinct_count = 0
    for prime in primes_through_sqrt_bound():
        if prime * prime > remaining:
            break
        if remaining % prime == 0:
            distinct_count += 1
            while remaining % prime == 0:
                remaining //= prime
    if remaining > 1:
        distinct_count += 1
    return -1 if distinct_count & 1 else 1
