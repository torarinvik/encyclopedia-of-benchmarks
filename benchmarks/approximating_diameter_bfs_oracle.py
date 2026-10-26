"""Rooted-BFS diameter estimate for the deterministic Chapter 566 profile."""

MAX_INPUT_LENGTH = 242
MAX_OUTPUT_BYTES = 8


def evaluate(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m = values[0], values[1]
    if not 1 <= n <= 16 or not 0 <= m <= 120 or len(values) != 2 + 2*m:
        return -1, b""
    adj = [[False] * n for _ in range(n)]
    for i in range(m):
        u, v = values[2 + 2*i:4 + 2*i]
        if not 0 <= u < v < n or adj[u][v]:
            return -1, b""
        adj[u][v] = adj[v][u] = True
    dist = [-1] * n
    dist[0] = 0
    queue = [0]
    head = 0
    while head < len(queue):
        u = queue[head]
        head += 1
        for v in range(n):
            if adj[u][v] and dist[v] < 0:
                dist[v] = dist[u] + 1
                queue.append(v)
    if any(d < 0 for d in dist):
        return -1, b""
    estimate = max(dist)
    return 8, int(estimate).to_bytes(8, "little", signed=True)
