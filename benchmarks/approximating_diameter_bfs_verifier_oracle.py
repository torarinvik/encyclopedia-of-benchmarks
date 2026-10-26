"""Independent Floyd–Warshall check of the vertex-zero diameter estimate."""

MAX_INPUT_LENGTH = 242
MAX_OUTPUT_BYTES = 8


def verify(values):
    if values is None or len(values) < 2 or len(values) > 242:
        return -1, b""
    n, m = values[0], values[1]
    if n < 1 or n > 16 or m < 0 or m > 120 or len(values) != 2 + 2*m:
        return -1, b""
    inf = n + 1
    d = [[inf] * n for _ in range(n)]
    for i in range(n):
        d[i][i] = 0
    seen = set()
    for i in range(m):
        u, v = values[2 + 2*i:4 + 2*i]
        if not 0 <= u < v < n or (u, v) in seen:
            return -1, b""
        seen.add((u, v))
        d[u][v] = d[v][u] = 1
    for k in range(n):
        for i in range(n):
            for j in range(n):
                d[i][j] = min(d[i][j], d[i][k] + d[k][j])
    if any(x >= inf for x in d[0]):
        return -1, b""
    return 8, max(d[0]).to_bytes(8, "little", signed=True)
