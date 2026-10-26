"""Independent repeated-best-edge model for the greedy matching profile."""

MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 16


def verify(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m = values[0], values[1]
    if n < 1 or n > 12 or m < 0 or m > 32 or len(values) != 2 + 3 * m:
        return -1, b""
    edges = []
    edge_keys = set()
    for j in range(m):
        u, v, weight = values[2 + 3*j:5 + 3*j]
        if u < 0 or u >= n or v < 0 or v >= n or u == v or weight < 1 or weight > 100:
            return -1, b""
        key = (u, v) if u < v else (v, u)
        if key in edge_keys:
            return -1, b""
        edge_keys.add(key)
        edges.append((u, v, weight))
    consumed = [False] * m
    occupied = [False] * n
    selected = 0
    total = 0
    for _ in range(m):
        best = -1
        for e in range(m):
            if not consumed[e] and (best < 0 or edges[e][2] > edges[best][2]):
                best = e
        if best < 0:
            break
        consumed[best] = True
        u, v, weight = edges[best]
        if not occupied[u] and not occupied[v]:
            occupied[u] = occupied[v] = True
            selected |= 1 << best
            total += weight
    raw = total.to_bytes(8, "little", signed=True) + selected.to_bytes(8, "little", signed=True)
    return 16, raw
