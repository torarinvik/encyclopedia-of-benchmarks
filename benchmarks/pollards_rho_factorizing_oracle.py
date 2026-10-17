"""Oracle for the bounded pinned C# Pollard-rho factorization method."""

from __future__ import annotations

from math import gcd

MIN_INPUT = 2
MAX_INPUT = 46_340
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(number: int) -> int:
    """Return the source's first non-one gcd, which may equal ``number``."""
    if type(number) is not int or not I64_MIN <= number <= I64_MAX:
        return INVALID_RESULT
    if not MIN_INPUT <= number <= MAX_INPUT:
        return INVALID_RESULT

    x = 2
    y = 2
    while True:
        x = (x * x + 1) % number
        y = (y * y + 1) % number
        y = (y * y + 1) % number
        divisor = gcd(abs(x - y), number)
        if divisor != 1:
            return divisor
