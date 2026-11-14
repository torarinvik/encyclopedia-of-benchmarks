"""Bounded-domain dynamic programming reference for L1 sequence fitting."""


def expected(values):
    if values is None or len(values) < 2 or len(values) > 130:
        return -1
    n, h = values[:2]
    if not 0 <= n <= 128 or not 0 <= h <= 100 or len(values) != n+2:
        return -1
    observations = values[2:]
    if any(not 0 <= x <= 100 for x in observations):
        return -1
    if n == 0:
        return 0
    cost = [abs(observations[0]-x) for x in range(101)]
    for a in observations[1:]:
        cost = [abs(a-x) + min(cost[max(0, x-h):min(100, x+h)+1])
                for x in range(101)]
    return min(cost)
