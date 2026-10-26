"""Primary oracle for one deterministic bottom-k all-distances sketch."""

MAX_INPUT_LENGTH = 104
MAX_OUTPUT_BYTES = 168


def evaluate(values):
    if values is None or not 6 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    n, m, k, source = values[:4]
    if any(not isinstance(x, int) for x in (n, m, k, source)):
        return -1, b""
    if not 2 <= n <= 10 or not 0 <= m <= n * (n - 1) or not 1 <= k <= n or not 0 <= source < n:
        return -1, b""
    if len(values) != 4 + n + 2 * m:
        return -1, b""
    ranks = values[4:4+n]
    if any(not isinstance(x, int) for x in ranks) or sorted(ranks) != list(range(n)):
        return -1, b""
    adj = [[] for _ in range(n)]
    seen = set()
    for i in range(m):
        u, v = values[4+n+2*i:6+n+2*i]
        if not isinstance(u, int) or not isinstance(v, int) or not 0 <= u < n or not 0 <= v < n or u == v or (u, v) in seen:
            return -1, b""
        seen.add((u, v))
        adj[u].append(v)
    dist = [-1] * n
    dist[source] = 0
    queue = [source]
    for u in queue:
        for v in adj[u]:
            if dist[v] < 0:
                dist[v] = dist[u] + 1
                queue.append(v)
    ordered = sorted((dist[v], v) for v in range(n) if dist[v] >= 0)
    sketch = []
    prior_ranks = []
    for d, v in ordered:
        # A node is retained iff its rank is among the k smallest ranks in
        # the source-neighborhood prefix ending at (d, v).
        if sum(r < ranks[v] for r in prior_ranks) < k:
            sketch.append((v, d))
        prior_ranks.append(ranks[v])
    words = [len(sketch)] + [x for pair in sketch for x in pair]
    raw = b"".join(int(x).to_bytes(8, "little", signed=True) for x in words)
    return len(raw), raw
