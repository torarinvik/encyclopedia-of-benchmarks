"""Factorization-based reference for the bounded perfect-totient predicate."""

from __future__ import annotations

MIN_INPUT = 3
MAX_INPUT = 65_535


def _phi(value: int) -> int:
    result = value
    remaining = value
    factor = 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            while remaining % factor == 0:
                remaining //= factor
            result -= result // factor
        factor += 1
    if remaining > 1:
        result -= result // remaining
    return result


def expected_result(n: int) -> int:
    if type(n) is not int or not MIN_INPUT <= n <= MAX_INPUT:
        return -1
    total = 0
    value = n
    while value > 1:
        value = _phi(value)
        total += value
    return int(total == n)
