"""Exact-count dynamic programming reference for a weighted path."""

INVALID = -1000000000


def expected(values):
    if values is None or len(values) < 2 or len(values) > 130:
        return INVALID
    n, k = values[:2]
    if not 0 <= n <= 128 or not 0 <= k <= (n+1)//2 or len(values) != n+2:
        return INVALID
    if any(not -1000 <= value <= 1000 for value in values[2:]):
        return INVALID
    impossible = -10**12
    previous_two = [0] + [impossible]*k
    previous_one = previous_two[:]
    for value in values[2:]:
        current = previous_one[:]
        for count in range(1, k+1):
            current[count] = max(current[count], previous_two[count-1]+value)
        previous_two, previous_one = previous_one, current
    return previous_one[k]


def enumerate_small(values):
    """Enumerate subsets for valid frames of at most 12 positions."""
    if values is None or len(values) < 2:
        return INVALID
    n, k = values[:2]
    if not 0 <= n <= 12 or not 0 <= k <= (n+1)//2 or len(values) != n+2:
        return INVALID
    if any(not -1000 <= value <= 1000 for value in values[2:]):
        return INVALID
    best = None
    for mask in range(1 << n):
        if mask & (mask << 1) or mask.bit_count() != k:
            continue
        score = sum(values[2+i] for i in range(n) if mask & (1 << i))
        if best is None or score > best:
            best = score
    return best if best is not None else INVALID
