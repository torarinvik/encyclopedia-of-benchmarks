"""Independent recurrence for Project Euler problem 2's even Fibonacci sum."""

MIN_THRESHOLD = -(1 << 31)
MAX_THRESHOLD = 1_000_000_000


def expected_result(threshold: int) -> int:
    """Sum even Fibonacci values not greater than the threshold.

    This oracle advances only the even-valued subsequence (2, 8, 34, ...),
    unlike the ports, which follow the pinned source's full Fibonacci pair.
    """
    if not MIN_THRESHOLD <= threshold <= MAX_THRESHOLD:
        return -1

    total = 0
    current, following = 2, 8
    while current <= threshold:
        total += current
        current, following = following, 4 * following + current
    return total
