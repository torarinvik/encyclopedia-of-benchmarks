"""Independent trial-division oracle for the Mersenne-prime predicate."""

from __future__ import annotations

MIN_EXPONENT = 2
MAX_EXPONENT = 31


def expected_result(value: int) -> int:
    if type(value) is not int or not MIN_EXPONENT <= value <= MAX_EXPONENT:
        return -1
    candidate = (1 << value) - 1
    if candidate < 2:
        return 0
    divisor = 2
    while divisor * divisor <= candidate:
        if candidate % divisor == 0:
            return 0
        divisor += 1
    return 1
