"""Independent oracle for the bounded primelib greatest-prime-factor contract."""

from __future__ import annotations

MIN_INPUT = 0
MAX_INPUT = 1_000_000


def expected_result(value: int) -> int:
    if type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT:
        return -1
    if value < 2:
        return value

    remaining = value
    largest = 1
    divisor = 2
    while divisor <= remaining // divisor:
        while remaining % divisor == 0:
            largest = divisor
            remaining //= divisor
        divisor = 3 if divisor == 2 else divisor + 2

    return remaining if remaining > 1 else largest
