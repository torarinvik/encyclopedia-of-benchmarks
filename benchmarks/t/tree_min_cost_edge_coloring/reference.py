"""Unexecuted small references for minimum-cost proper tree edge coloring."""
from itertools import permutations, product


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 82
            or any(type(value) is not int for value in values)):
        return None
    n, k = values[:2]
    if not 1 <= n <= 64 or not 1 <= k <= 16 or len(values) != n + 1 + k:
        return None
    parents, costs = values[2:n+1], values[n+1:]
    if (any(not 0 <= parent < vertex for vertex, parent in enumerate(parents, 1))
            or any(not 0 <= cost <= 1_000_000 for cost in costs)):
        return None
    return n, k, parents, costs


def subset_reference(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, k, parents, costs = parsed
    children = [[] for _ in range(n)]
    degree = [0] * n
    for vertex, parent in enumerate(parents, 1):
        children[parent].append(vertex)
        degree[parent] += 1
        degree[vertex] += 1
    if max(degree) > k:
        return -2
    if k > 8:
        raise ValueError("subset reference is restricted to at most eight colors")
    # dp[v][c] excludes the cost of v's parent edge and reserves color c at v;
    # sentinel k means no parent edge. Each child is assigned a distinct color.
    dp = [[0] * (k + 1) for _ in range(n)]
    for v in range(n-1, -1, -1):
        for forbidden in range(k+1):
            states = {0: 0}
            for child in children[v]:
                following = {}
                for used, current in states.items():
                    for color in range(k):
                        if color == forbidden or used & (1 << color):
                            continue
                        mask = used | (1 << color)
                        value = current + costs[color] + dp[child][color]
                        if mask not in following or value < following[mask]:
                            following[mask] = value
                states = following
            dp[v][forbidden] = min(states.values(), default=10**15)
    return dp[0][k]


def brute_small(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, k, parents, costs = parsed
    if k ** (n-1) > 100000:
        raise ValueError("exhaustive reference bound exceeded")
    best = None
    for colors in product(range(k), repeat=n-1):
        used = [set() for _ in range(n)]
        valid = True
        for vertex, (parent, color) in enumerate(zip(parents, colors), 1):
            if color in used[parent] or color in used[vertex]:
                valid = False
                break
            used[parent].add(color)
            used[vertex].add(color)
        if valid:
            cost = sum(costs[color] for color in colors)
            best = cost if best is None else min(best, cost)
    return -2 if best is None else best


def deletion_costs_brute(cost):
    """Exhaustive oracle for each single-column deletion, at small degree."""
    d = len(cost)
    if d > 7 or any(len(row) != d+1 for row in cost):
        raise ValueError("oracle requires at most seven rows and one extra column")
    results = []
    for excluded in range(d+1):
        columns = [column for column in range(d+1) if column != excluded]
        results.append(min(sum(cost[row][column] for row, column in enumerate(order))
                           for order in permutations(columns)))
    return results
