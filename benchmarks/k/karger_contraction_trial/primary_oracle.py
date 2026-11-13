"""Disjoint-set replay of the bounded Karger contraction trial."""

MAX_INPUT_LENGTH = 57


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1
    n, m = values[:2]
    if not 2 <= n <= 8 or not 1 <= m <= 24 or len(values) != 2 + 2 * m + n - 2:
        return -1
    edges = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(m)]
    if any(u < 0 or u >= n or v < 0 or v >= n or u == v for u, v in edges):
        return -1
    parent = list(range(n))

    def root(vertex):
        while parent[vertex] != vertex:
            vertex = parent[vertex]
        return vertex

    for u, v in edges:
        parent[root(u)] = root(v)
    if any(root(vertex) != root(0) for vertex in range(1, n)):
        return -1
    parent = list(range(n))
    for rank in values[2 + 2 * m:]:
        live = sum(root(u) != root(v) for u, v in edges)
        if rank < 0 or rank >= live:
            return -1
        for u, v in edges:
            left, right = root(u), root(v)
            if left == right:
                continue
            if rank == 0:
                parent[left] = right
                break
            rank -= 1
    return sum(root(u) != root(v) for u, v in edges)
