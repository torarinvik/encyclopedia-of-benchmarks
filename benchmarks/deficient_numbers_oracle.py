"""Factorization model for the bounded deficient-number predicate."""


def expected_result(value):
    if value <= 0:
        return 0
    if value > 100_000_000:
        return -1
    remaining, sigma, factor = value, 1, 2
    while factor * factor <= remaining:
        power, series = 1, 1
        while remaining % factor == 0:
            remaining //= factor
            power *= factor
            series += power
        sigma *= series
        factor += 1
    if remaining > 1:
        sigma *= remaining + 1
    return int(sigma < 2 * value)
