"""Independent bounded reference for Project Euler Problem 21 pair sums."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_LIMIT = 2
MAX_LIMIT = 10_000
INVALID_RESULT = -1


def _proper_divisor_sums(bound: int) -> list[int]:
    sums = [0] * (bound + 1)
    for divisor in range(1, bound // 2 + 1):
        for multiple in range(divisor * 2, bound + 1, divisor):
            sums[multiple] += divisor
    return sums


def expected_output(limit: int) -> int:
    """Sum both members of each qualifying pair whose smaller member is < limit."""
    if type(limit) is not int or not I64_MIN <= limit <= I64_MAX:
        return INVALID_RESULT
    if not MIN_LIMIT <= limit <= MAX_LIMIT:
        return INVALID_RESULT

    sums_below_limit = _proper_divisor_sums(limit - 1)
    max_partner = max(sums_below_limit, default=0)
    sums_through_partner = _proper_divisor_sums(max(limit - 1, max_partner))

    total = 0
    for smaller in range(2, limit):
        larger = sums_below_limit[smaller]
        if larger > smaller and sums_through_partner[larger] == smaller:
            total += smaller + larger
    return total
