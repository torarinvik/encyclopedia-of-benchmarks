"""Digit-sum reference for the bounded prime valuation of a factorial."""
import math


def expected_result(n, prime):
    if not 0 <= n <= 2**32-1 or not 2 <= prime <= 65535:
        return -1
    if any(prime % factor == 0 for factor in range(2, math.isqrt(prime) + 1)):
        return -1
    remaining, digit_sum = n, 0
    while remaining:
        remaining, digit = divmod(remaining, prime)
        digit_sum += digit
    return (n - digit_sum) // (prime - 1)
