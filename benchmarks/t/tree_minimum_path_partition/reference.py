"""Unexecuted references for minimum vertex-disjoint paths in a tree."""


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 65
            or any(type(value) is not int for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= 64 or len(values) != n:
        return None
    parents = values[1:]
    if any(not 0 <= parent < vertex for vertex, parent in enumerate(parents, 1)):
        return None
    return n, parents


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, parents = parsed
    children = [[] for _ in range(n)]
    for child, parent in enumerate(parents, 1):
        children[parent].append(child)
    absent, present = [0]*n, [0]*n
    for vertex in range(n-1, -1, -1):
        base = sum(absent[child] for child in children[vertex])
        gains = sorted((1 + present[child] - absent[child]
                        for child in children[vertex]), reverse=True)
        positive = [gain for gain in gains if gain > 0]
        absent[vertex] = base + sum(positive[:2])
        present[vertex] = base + sum(positive[:1])
    return n - absent[0]


def brute_small(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, parents = parsed
    if n > 16:
        raise ValueError("exhaustive reference is restricted to 16 vertices")
    best = 0
    for mask in range(1 << (n-1)):
        degree = [0]*n
        for child, parent in enumerate(parents, 1):
            if mask & (1 << (child-1)):
                degree[child] += 1
                degree[parent] += 1
        if all(value <= 2 for value in degree):
            best = max(best, mask.bit_count())
    return n - best
