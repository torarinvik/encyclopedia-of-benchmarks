"""Unexecuted references for minimum-weight tree vertex cover."""


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 129
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
    # Complement of a minimum cover is a maximum-weight independent set.
    take, omit = list(weights), [0] * n
    for vertex in range(n-1, 0, -1):
        parent = parents[vertex-1]
        take[parent] += omit[vertex]
        omit[parent] += max(take[vertex], omit[vertex])
    return sum(weights) - max(take[0], omit[0])


def brute_small(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, parents, weights = parsed
    if n > 16:
        raise ValueError("exhaustive reference is restricted to 16 vertices")
    best = sum(weights)
    for mask in range(1 << n):
        if all((mask >> child) & 1 or (mask >> parents[child-1]) & 1 for child in range(1, n)):
            best = min(best, sum(weights[v] for v in range(n) if (mask >> v) & 1))
    return best
