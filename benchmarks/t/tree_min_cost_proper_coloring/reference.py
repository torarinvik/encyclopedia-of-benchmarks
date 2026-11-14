"""Unexecuted references for minimum-cost proper tree coloring."""


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 1090
            or any(type(value) is not int for value in values)):
        return None
    n, colors = values[:2]
    if not 1 <= n <= 64 or not 1 <= colors <= 16 or len(values) != n + 1 + n * colors:
        return None
    parents = values[2:n+1]
    costs = values[n+1:]
    if (any(not 0 <= parent < vertex for vertex, parent in enumerate(parents, 1))
            or any(not 0 <= cost <= 1_000_000 for cost in costs)):
        return None
    return n, colors, parents, costs


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, colors, parents, costs = parsed
    if n > 1 and colors == 1:
        return -2
    dp = [list(costs[i*colors:(i+1)*colors]) for i in range(n)]
    for child in range(n-1, 0, -1):
        parent = parents[child-1]
        for color in range(colors):
            dp[parent][color] += min(dp[child][other] for other in range(colors) if other != color)
    return min(dp[0])


def brute_small(values):
    from itertools import product
    parsed = parse(values)
    if parsed is None:
        return -1
    n, colors, parents, costs = parsed
    if colors**n > 100000:
        raise ValueError("exhaustive reference bound exceeded")
    best = None
    for assignment in product(range(colors), repeat=n):
        if any(assignment[child] == assignment[parents[child-1]] for child in range(1, n)):
            continue
        total = sum(costs[i*colors+assignment[i]] for i in range(n))
        best = total if best is None else min(best, total)
    return -2 if best is None else best
