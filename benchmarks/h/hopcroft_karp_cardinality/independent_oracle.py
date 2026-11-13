"""Bipartite matching cardinality by individual augmenting paths."""


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1
    left, right, edges = values[:3]
    if not 0 <= left <= 64 or not 0 <= right <= 64 or not 0 <= edges <= 4096 or len(values) != 3 + 2 * edges:
        return -1
    adjacency = [set() for _ in range(left)]
    for offset in range(3, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < left or not 0 <= v < right:
            return -1
        adjacency[u].add(v)
    matched = [-1] * right

    def augment(u, seen):
        for v in adjacency[u]:
            if v in seen:
                continue
            seen.add(v)
            if matched[v] < 0 or augment(matched[v], seen):
                matched[v] = u
                return True
        return False

    return sum(augment(u, set()) for u in range(left))
