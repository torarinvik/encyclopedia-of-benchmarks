"""Directed girth via all-pairs shortest paths and a closing edge."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 2 <= len(values) <= 131
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, m = values[:2]
    if not 1 <= n <= 16 or not 0 <= m <= 64 or len(values) != 2 + 2*m:
        return -1
    edges = list(zip(values[2::2], values[3::2]))
    if any(not 0 <= u < n or not 0 <= v < n for u, v in edges):
        return -1
    infinity = n + 1
    dist = [[infinity] * n for _ in range(n)]
    for v in range(n):
        dist[v][v] = 0
    for u, v in edges:
        dist[u][v] = min(dist[u][v], 1)
    for k in range(n):
        for u in range(n):
            for v in range(n):
                dist[u][v] = min(dist[u][v], dist[u][k] + dist[k][v])
    best = min((1 + dist[v][u] for u, v in edges), default=infinity)
    return best if best <= n else 0
