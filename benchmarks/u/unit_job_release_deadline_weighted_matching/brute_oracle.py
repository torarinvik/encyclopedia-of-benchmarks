"""Exhaustive reference for small valid scheduling frames; never called by the runner."""

from functools import lru_cache


def expected_small(values):
    n = values[0]
    if not 0 <= n <= 8 or len(values) != 1 + 3*n:
        raise ValueError("expected a small, valid frame")
    jobs = [tuple(values[1+3*i:4+3*i]) for i in range(n)]
    if any(not 0 <= start <= end < 32 or not 0 <= weight <= 1_000_000
           for start, end, weight in jobs):
        raise ValueError("expected a small, valid frame")

    @lru_cache(None)
    def solve(index, occupied):
        if index == n:
            return 0
        start, end, weight = jobs[index]
        best = solve(index + 1, occupied)
        for slot in range(start, end + 1):
            bit = 1 << slot
            if not occupied & bit:
                best = max(best, weight + solve(index + 1, occupied | bit))
        return best

    return solve(0, 0)
