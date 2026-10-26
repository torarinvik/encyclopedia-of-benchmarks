"""Independent combination-enumeration verifier for bounded k-median p=1."""

from itertools import combinations

MAX_INPUT_LENGTH = 150
MAX_OUTPUT_BYTES = 48


def verify(values, capacity=None, output_is_null=False):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if any(not isinstance(x, int) for x in values):
        return -1, b""
    n, k = values[0], values[1]
    if not 2 <= n <= 12 or not 1 <= k <= min(4, n) or len(values) != 2+n*n+k:
        return -1, b""
    raw = values[2:2+n*n]
    if any(x < 0 or x > 1000 for x in raw):
        return -1, b""
    d = tuple(tuple(raw[i*n:(i+1)*n]) for i in range(n))
    for i in range(n):
        if d[i][i] != 0: return -1, b""
        for j in range(n):
            if d[i][j] != d[j][i] or (i != j and d[i][j] == 0): return -1, b""
            for h in range(n):
                if d[i][j] > d[i][h] + d[h][j]: return -1, b""
    initial = tuple(sorted(values[2+n*n:]))
    if len(initial) != k or len(set(initial)) != k or any(c < 0 or c >= n for c in initial):
        return -1, b""

    def objective(cs):
        return sum(min(d[i][c] for c in cs) for i in range(n))

    centers = initial
    value = objective(centers)
    while True:
        neighbors = []
        selected = set(centers)
        for candidate in combinations(range(n), k):
            if len(selected.intersection(candidate)) != k-1:
                continue
            score = objective(candidate)
            if score < value:
                neighbors.append((score, candidate))
        if not neighbors:
            break
        value, centers = min(neighbors)
    result = (value, k, *centers)
    out = b"".join(int(x).to_bytes(8, "little", signed=True) for x in result)
    if output_is_null or (capacity is not None and capacity < len(out)):
        return -2, b""
    return len(out), out
