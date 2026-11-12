"""Bounded reference oracle for summatory square-free counting."""
from __future__ import annotations

from math import isqrt

MAX_N = 1_000_000_000_000
INVALID_RESULT = -1


def expected_result(value: int, algorithm: str = "counting_squarefrees") -> int:
    if algorithm != "counting_squarefrees" or type(value) is not int:
        return INVALID_RESULT
    if not 1 <= value <= MAX_N:
        return INVALID_RESULT

    limit = isqrt(value)
    mobius = [1] * (limit + 1)
    composite = bytearray(limit + 1)
    for prime in range(2, limit + 1):
        if composite[prime]:
            continue
        square = prime * prime
        if square <= limit:
            for multiple in range(square, limit + 1, prime):
                composite[multiple] = 1
        for multiple in range(prime, limit + 1, prime):
            mobius[multiple] = -mobius[multiple]
        for multiple in range(square, limit + 1, square):
            mobius[multiple] = 0

    return sum(
        mobius[divisor] * (value // (divisor * divisor))
        for divisor in range(1, limit + 1)
    )
