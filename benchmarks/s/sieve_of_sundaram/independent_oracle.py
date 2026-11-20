"""Independent direct-division reference for counting primes up to a limit."""

from __future__ import annotations

from math import isqrt

MAX_LIMIT = 4096


def _is_prime(candidate: int) -> bool:
    if candidate < 2:
        return False
    if candidate % 2 == 0:
        return candidate == 2
    divisor = 3
    while divisor <= isqrt(candidate):
        if candidate % divisor == 0:
            return False
        divisor += 2
    return True


def prime_count(limit: int) -> int:
    if type(limit) is not int or not 0 <= limit <= MAX_LIMIT:
        return -1
    return sum(_is_prime(value) for value in range(2, limit + 1))
