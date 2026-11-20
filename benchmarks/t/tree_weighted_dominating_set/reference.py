"""Unexecuted reference models for minimum-weight tree domination."""


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
    children = [[] for _ in range(n)]
    for vertex, parent in enumerate(parents, 1):
        children[parent].append(vertex)
    inf = 10**12
    selected, covered, waiting = [0]*n, [inf]*n, [0]*n
    for vertex in range(n-1, -1, -1):
        selected[vertex] = weights[vertex] + sum(
            min(selected[c], covered[c], waiting[c]) for c in children[vertex])
        waiting[vertex] = min(inf, sum(covered[c] for c in children[vertex]))
        # Force one chosen child; the others may already be covered.
        covered[vertex] = min((selected[chosen] + sum(
            min(selected[c], covered[c]) for c in children[vertex] if c != chosen)
                               for chosen in children[vertex]), default=inf)
    return min(selected[0], covered[0])


def brute_small(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, parents, weights = parsed
    if n > 16:
        raise ValueError("exhaustive reference is restricted to 16 vertices")
    neighborhoods = [1 << vertex for vertex in range(n)]
    for child, parent in enumerate(parents, 1):
        neighborhoods[child] |= 1 << parent
        neighborhoods[parent] |= 1 << child
    best = sum(weights)
    for mask in range(1 << n):
        if all(mask & neighborhood for neighborhood in neighborhoods):
            best = min(best, sum(weights[v] for v in range(n) if (mask >> v) & 1))
    return best
