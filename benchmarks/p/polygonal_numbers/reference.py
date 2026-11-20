"""Combination-based model for the bounded polygonal-number profile."""


def expected(values):
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return -1
    if any(type(value) is not int for value in values):
        return -1
    n, sides = values
    if not 0 <= n <= 100_000_000 or not 3 <= sides <= 64:
        return -1
    return n + (sides - 2) * (n * (n - 1) // 2)
