"""Stable max-weight greedy matching oracle for Chapter 570."""

MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 16


def evaluate(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m = values[0], values[1]
    if not 1 <= n <= 12 or not 0 <= m <= 32 or len(values) != 2 + 3 * m:
        return -1, b""
    edges = []
    seen = set()
    for i in range(m):
        u, v, weight = values[2 + 3 * i:5 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v or not 1 <= weight <= 100:
            return -1, b""
        edge = (min(u, v), max(u, v))
        if edge in seen:
            return -1, b""
        seen.add(edge)
        edges.append((u, v, weight))
    order = sorted(range(m), key=lambda i: (-edges[i][2], i))
    matched = [False] * n
    selected_mask = 0
    total_weight = 0
    for i in order:
        u, v, weight = edges[i]
        if not matched[u] and not matched[v]:
            matched[u] = matched[v] = True
            selected_mask |= 1 << i
            total_weight += weight
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in (total_weight, selected_mask))
    return 16, raw
