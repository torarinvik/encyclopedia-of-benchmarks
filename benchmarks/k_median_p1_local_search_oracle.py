"""Deterministic bounded p=1 k-median local-search oracle."""

MAX_N = 12
MAX_K = 4
MAX_INPUT_LENGTH = 150
MAX_OUTPUT_ELEMENTS = 2 + MAX_K
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS


def _parse(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(not isinstance(x, int) for x in values):
        return None
    n, k = values[:2]
    if not 2 <= n <= MAX_N or not 1 <= k <= min(MAX_K, n):
        return None
    if len(values) != 2 + n*n + k:
        return None
    flat = values[2:2+n*n]
    if any(d < 0 or d > 1000 for d in flat):
        return None
    dist = [flat[i*n:(i+1)*n] for i in range(n)]
    for i in range(n):
        if dist[i][i] != 0:
            return None
        for j in range(n):
            if i != j and dist[i][j] == 0:
                return None
            if dist[i][j] != dist[j][i]:
                return None
    for i in range(n):
        for j in range(n):
            for h in range(n):
                if dist[i][j] > dist[i][h] + dist[h][j]:
                    return None
    centers = values[2+n*n:]
    if len(set(centers)) != k or any(c < 0 or c >= n for c in centers):
        return None
    return n, k, dist, tuple(sorted(centers))


def _cost(dist, centers):
    return sum(min(dist[i][c] for c in centers) for i in range(len(dist)))


def _solve(n, k, dist, initial):
    centers = initial
    current_cost = _cost(dist, centers)
    while True:
        best_cost = current_cost
        best_centers = centers
        selected = set(centers)
        for leaving in centers:
            for entering in range(n):
                if entering in selected:
                    continue
                candidate = tuple(sorted((selected - {leaving}) | {entering}))
                value = _cost(dist, candidate)
                if value < best_cost or (value == best_cost and value < current_cost and candidate < best_centers):
                    best_cost, best_centers = value, candidate
        if best_cost >= current_cost:
            return current_cost, centers
        current_cost, centers = best_cost, best_centers


def expected_output(values, capacity=None, output_is_null=False):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, k, dist, initial = parsed
    cost, centers = _solve(n, k, dist, initial)
    result = (cost, k, *centers)
    output = b"".join(int(x).to_bytes(8, "little", signed=True) for x in result)
    needed = len(output)
    if output_is_null or (capacity is not None and capacity < needed):
        return -2, b""
    return needed, output


def evaluate(values):
    return expected_output(values)
