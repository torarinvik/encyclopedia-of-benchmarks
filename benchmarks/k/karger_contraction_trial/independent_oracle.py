"""Replay contractions using explicit per-vertex component labels."""

MAX_INPUT_LENGTH = 57


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 57
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, m = values[:2]
    if not 2 <= n <= 8 or not 1 <= m <= 24 or len(values) != 2 + 2 * m + n - 2:
        return -1
    edges = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(m)]
    if any(not (0 <= u < n and 0 <= v < n) or u == v for u, v in edges):
        return -1
    reached = {0}
    while True:
        expanded = reached | {v for u, v in edges if u in reached} | {u for u, v in edges if v in reached}
        if expanded == reached:
            break
        reached = expanded
    if len(reached) != n:
        return -1
    labels = list(range(n))
    for rank in values[2 + 2 * m:]:
        live = [(u, v) for u, v in edges if labels[u] != labels[v]]
        if not 0 <= rank < len(live):
            return -1
        u, v = live[rank]
        old, new = labels[u], labels[v]
        labels = [new if label == old else label for label in labels]
    return sum(labels[u] != labels[v] for u, v in edges)
