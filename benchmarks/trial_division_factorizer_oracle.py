"""Oracle for the bounded C# trial-division factorizer."""

from __future__ import annotations

I32_MIN, I32_MAX = -(2**31), 2**31 - 1


def expected_result(value: int) -> int:
    if type(value) is not int or not I32_MIN <= value <= I32_MAX or value in (0, I32_MIN):
        return -1
    number = abs(value)
    divisor = 2
    while divisor <= number // divisor:
        if number % divisor == 0:
            return divisor
        divisor += 1
    return 0
