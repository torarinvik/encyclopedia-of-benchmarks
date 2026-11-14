"""Edge-subset reference for the bounded unit-resistance profile."""
from itertools import combinations
from math import gcd


def expected(values):
    if not isinstance(values, (tuple, list)) or len(values) < 4:
        return -1
    if any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in values):
        return -1
    n, m, s, t = values[:4]
    if not (2 <= n <= 6 and 0 <= m <= 15 and 0 <= s < n and 0 <= t < n
            and s != t and len(values) == 4 + 2*m):
        return -1
    edges = set()
    for i in range(m):
        u, v = values[4+2*i:6+2*i]
        if not (0 <= u < n and 0 <= v < n) or u == v:
            return -1
        edge = (min(u, v), max(u, v))
        if edge in edges:
            return -1
        edges.add(edge)
    edges = sorted(edges)

    def count(size, separating):
        result = 0
        for subset in combinations(edges, size):
            parent = list(range(n))
            def root(v):
                while parent[v] != v:
                    v = parent[v]
                return v
            acyclic = True
            for u, v in subset:
                a, b = root(u), root(v)
                if a == b:
                    acyclic = False
                    break
                parent[a] = b
            if acyclic and (not separating or root(s) != root(t)):
                result += 1
        return result

    trees = count(n-1, False)
    if not trees:
        return -1
    forests = count(n-2, True)
    divisor = gcd(trees, forests)
    return (forests//divisor)*65536 + trees//divisor
