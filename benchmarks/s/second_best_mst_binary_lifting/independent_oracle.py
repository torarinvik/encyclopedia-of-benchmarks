"""Enumerate spanning trees independently of the lifting implementation."""

from itertools import combinations


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 63
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, m = values[:2]
    if not 1 <= n <= 8 or not n - 1 <= m <= 20 or len(values) != 2 + 3 * m:
        return -1
    edges = []
    seen = set()
    for offset in range(2, len(values), 3):
        u, v, weight = values[offset:offset + 3]
        if not 0 <= u < v < n or not 0 <= weight <= 1_000_000 or (u, v) in seen:
            return -1
        seen.add((u, v))
        edges.append((u, v, weight))
    weights = set()
    for selection in combinations(edges, n - 1):
        component = list(range(n))
        for u, v, _ in selection:
            old, new = component[v], component[u]
            if old == new:
                break
            component = [new if label == old else label for label in component]
        else:
            if len(set(component)) == 1:
                weights.add(sum(weight for _, _, weight in selection))
    if not weights:
        return -1
    ordered = sorted(weights)
    return ordered[1] + 1 if len(ordered) > 1 else 0
