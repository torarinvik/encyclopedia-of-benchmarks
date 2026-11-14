"""Unexecuted exhaustive minimum-cut reference for the bounded flow contract."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 4 <= len(values) <= 197
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in values)):
        return -1
    n, m, source, sink = values[:4]
    if not (2 <= n <= 16 and 0 <= m <= 64 and 1 <= source <= n
            and 1 <= sink <= n and source != sink and len(values) == 4+3*m):
        return -1
    edges = []
    for i in range(m):
        u, v, capacity = values[4+3*i:7+3*i]
        if not (1 <= u <= n and 1 <= v <= n and u != v and 0 <= capacity <= 100):
            return -1
        edges.append((u-1, v-1, capacity))
    source -= 1
    sink -= 1
    others = [vertex for vertex in range(n) if vertex != source and vertex != sink]
    best = 6401
    for mask in range(1 << len(others)):
        inside = 1 << source
        for index, vertex in enumerate(others):
            if mask & (1 << index):
                inside |= 1 << vertex
        cut = sum(capacity for u, v, capacity in edges if inside & (1 << u) and not inside & (1 << v))
        best = min(best, cut)
    return best
