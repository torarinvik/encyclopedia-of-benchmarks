"""Primary oracle for Chapter 99's single local domination reduction."""

MAX_INPUT_LENGTH = 135
MAX_OUTPUT_BYTES = 200


def evaluate(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m, pivot = values[:3]
    if not 1 <= n <= 12 or not 0 <= m <= 66 or not 0 <= pivot < n or len(values) != 3 + 2 * m:
        return -1, b""
    adj = [[False] * n for _ in range(n)]
    for i in range(m):
        u, v = values[3 + 2*i:5 + 2*i]
        if not 0 <= u < v < n or adj[u][v]:
            return -1, b""
        adj[u][v] = adj[v][u] = True

    closed = {pivot} | {u for u in range(n) if adj[pivot][u]}
    neighbors = sorted(closed - {pivot})
    exits = {u for u in neighbors if any(adj[u][x] for x in range(n) if x not in closed)}
    guards = {u for u in neighbors if u not in exits and any(adj[u][x] for x in exits)}
    prisoners = set(neighbors) - exits - guards
    if not prisoners:
        return -1, b""

    removed = guards | prisoners
    kept = [u for u in range(n) if u not in removed]
    ids = kept + [-1]  # the new gadget leaf is always last
    k = len(ids)
    remap = {old: new for new, old in enumerate(kept)}
    rows = [0] * k
    for a, old_a in enumerate(kept):
        for old_b in kept:
            if adj[old_a][old_b]:
                rows[a] |= 1 << remap[old_b]
    gadget = k - 1
    rows[remap[pivot]] |= 1 << gadget
    rows[gadget] = 1 << remap[pivot]

    words = [k, *ids, *rows]
    encoded = b"".join(int(x).to_bytes(8, "little", signed=True) for x in words)
    return len(encoded), encoded
