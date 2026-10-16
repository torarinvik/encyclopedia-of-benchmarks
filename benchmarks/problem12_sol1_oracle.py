"""Independent expected values for the fixed-input Project Euler Problem 12 sol1 package."""

from __future__ import annotations

from functools import lru_cache

CANONICAL_THRESHOLD = 500
INVALID_RESULT = -1


def _divisor_count(value: int) -> int:
    """Count divisors by prime exponents for the oracle's split factors."""
    remaining = value
    count = 1
    factor = 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            exponent = 0
            while remaining % factor == 0:
                remaining //= factor
                exponent += 1
            count *= exponent + 1
        factor += 1
    if remaining > 1:
        count *= 2
    return count


@lru_cache(maxsize=1)
def _canonical_result() -> int:
    """Use coprime consecutive halves instead of factoring each triangle."""
    for index in range(1, 12_376):
        left, right = index, index + 1
        if index % 2 == 0:
            left //= 2
        else:
            right //= 2
        if _divisor_count(left) * _divisor_count(right) > CANONICAL_THRESHOLD:
            return index * (index + 1) // 2
    return INVALID_RESULT


def expected_result(threshold: int) -> int:
    """Return the oracle answer for the sole shared input value."""
    if type(threshold) is not int or threshold != CANONICAL_THRESHOLD:
        return INVALID_RESULT
    return _canonical_result()
