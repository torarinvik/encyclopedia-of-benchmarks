"""Coprime-count oracle for the iterated-totient predicate."""

from __future__ import annotations

from math import gcd

MIN_INPUT = 3
MAX_INPUT = 65_535


def _count_coprimes(value: int) -> int:
    return sum(gcd(candidate, value) == 1
               for candidate in range(1, value + 1))


def expected_result(n: int) -> int:
    if type(n) is not int or not MIN_INPUT <= n <= MAX_INPUT:
        return -1
    chain_sum = 0
    current = n
    while current > 1:
        current = _count_coprimes(current)
        chain_sum += current
    return int(chain_sum == n)
