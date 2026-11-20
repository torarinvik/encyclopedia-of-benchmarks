"""Unexecuted references for weighted total domination on a tree."""


def parse(values):
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= 129
            or any(type(value) is not int for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= 64 or len(values) != 2*n:
        return None
    parents, weights = values[1:n], values[n:]
    if (any(not 0 <= parent < vertex for vertex, parent in enumerate(parents, 1))
            or any(not 0 <= weight <= 1_000_000 for weight in weights)):
        return None
    return n, parents, weights


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, parents, weights = parsed
    children = [[] for _ in range(n)]
    for vertex, parent in enumerate(parents, 1):
        children[parent].append(vertex)
    inf = 10**12
    # dp[v][chosen][parent_chosen], with all subtree vertices dominated.
    dp = [[[inf, inf] for _ in range(2)] for _ in range(n)]
    for v in range(n-1, -1, -1):
        for chosen in range(2):
            no_chosen_child, some_chosen_child = 0, inf
            for child in children[v]:
                absent = dp[child][0][chosen]
                present = dp[child][1][chosen]
                some_chosen_child = min(inf, some_chosen_child + min(absent, present),
                                        no_chosen_child + present)
                no_chosen_child = min(inf, no_chosen_child + absent)
            dp[v][chosen][0] = min(inf, chosen*weights[v] + some_chosen_child)
            dp[v][chosen][1] = min(inf, chosen*weights[v] + min(no_chosen_child, some_chosen_child))
    result = min(dp[0][0][0], dp[0][1][0])
    return -2 if result == inf else result


def brute_small(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, parents, weights = parsed
    if n > 16:
        raise ValueError("exhaustive reference is restricted to 16 vertices")
    neighbors = [0]*n
    for child, parent in enumerate(parents, 1):
        neighbors[child] |= 1 << parent
        neighbors[parent] |= 1 << child
    best = None
    for mask in range(1 << n):
        if all(mask & adjacent for adjacent in neighbors):
            cost = sum(weights[v] for v in range(n) if mask >> v & 1)
            best = cost if best is None else min(best, cost)
    return -2 if best is None else best
