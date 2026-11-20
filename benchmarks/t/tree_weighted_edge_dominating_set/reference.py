"""Unexecuted models for minimum-weight edge domination on a rooted tree."""


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 128
            or any(type(value) is not int for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= 64 or len(values) != 2*n-1:
        return None
    parents, weights = values[1:n], values[n:]
    if (any(not 0 <= parent < child for child, parent in enumerate(parents, 1))
            or any(not 0 <= weight <= 1_000_000 for weight in weights)):
        return None
    return n, parents, weights


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, parents, weights = parsed
    children = [[] for _ in range(n)]
    for child, parent in enumerate(parents, 1):
        children[parent].append((child, weights[child-1]))
    inf = 10**12
    selected, uncovered, pending = [inf]*n, [0]*n, [0]*n
    for vertex in range(n-1, -1, -1):
        no_selected, has_selected = 0, inf
        for child, weight in children[vertex]:
            skip = min(selected[child], uncovered[child])
            take = weight + min(selected[child], pending[child])
            has_selected = min(has_selected + min(skip, take), no_selected + take, inf)
            no_selected = min(no_selected + skip, inf)
        selected[vertex] = has_selected
        uncovered[vertex] = min(inf, sum(selected[c] for c, _ in children[vertex]))
        pending[vertex] = no_selected
    return min(selected[0], uncovered[0])


def brute_small(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, parents, weights = parsed
    if n > 16:
        raise ValueError("exhaustive reference is restricted to 16 vertices")
    edges = [(parent, child) for child, parent in enumerate(parents, 1)]
    best = sum(weights)
    for mask in range(1 << len(edges)):
        if all(any(mask & (1 << j) and (a == c or a == d or b == c or b == d)
                   for j, (c, d) in enumerate(edges)) for a, b in edges):
            best = min(best, sum(weight for i, weight in enumerate(weights)
                                 if mask & (1 << i)))
    return best
