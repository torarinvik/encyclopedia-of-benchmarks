"""Factorization model for the bounded divisor-count sequence."""


def expected_result(index):
    if not 0 <= index <= 9999:
        return -1
    remaining = index + 1
    result = 1
    factor = 2
    while factor * factor <= remaining:
        exponent = 0
        while remaining % factor == 0:
            remaining //= factor
            exponent += 1
        result *= exponent + 1
        factor += 1
    if remaining > 1:
        result *= 2
    return result
