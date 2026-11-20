"""Reverse-search triangulations of a convex point set from its Delaunay root."""

from itertools import combinations

MAX_VERTICES = 8
MAX_DIAGONALS = 20
MAX_VALID_INPUT_LENGTH = 28
MAX_PARSEABLE_INPUT_LENGTH = 29
MAX_TRIANGULATIONS = 132
WORKSPACE_BYTES = 4096


def _orient(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _incircle(a, b, c, d):
    """Positive exactly when d is inside the circle through CCW a,b,c."""
    ax, ay = a[0] - d[0], a[1] - d[1]
    bx, by = b[0] - d[0], b[1] - d[1]
    cx, cy = c[0] - d[0], c[1] - d[1]
    alift, blift, clift = ax * ax + ay * ay, bx * bx + by * by, cx * cx + cy * cy
    return (alift * (bx * cy - by * cx)
            - blift * (ax * cy - ay * cx)
            + clift * (ax * by - ay * bx))


def _diagonals(n):
    return [(u, v) for u in range(n) for v in range(u + 1, n)
            if v != u + 1 and (u != 0 or v != n - 1)]


def _crosses(first, second):
    a, b = first
    c, d = second
    return (a < c < b < d) or (c < a < d < b)


def _has_edge(mask, pair, index):
    u, v = pair
    if v == u + 1 or (u == 0 and v == index["n"] - 1):
        return True
    bit = index["pair_to_bit"].get((u, v))
    return bit is not None and (mask & (1 << bit)) != 0


def _triangles(mask, n, diagonal_list, pair_to_bit):
    index = {"n": n, "pair_to_bit": pair_to_bit}
    edges = [[False] * n for _ in range(n)]
    for u in range(n):
        v = (u + 1) % n
        edges[u][v] = edges[v][u] = True
    for bit, (u, v) in enumerate(diagonal_list):
        if mask & (1 << bit):
            edges[u][v] = edges[v][u] = True
    answer = []
    for a, b, c in combinations(range(n), 3):
        if edges[a][b] and edges[b][c] and edges[a][c]:
            answer.append((a, b, c))
    return answer


def _parse(values):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 3 <= n <= MAX_VERTICES or len(values) != 4 * n - 4:
        return None
    points = []
    for vertex in range(n):
        x, y = values[1 + 2 * vertex:3 + 2 * vertex]
        if not (-50 <= x <= 50 and -50 <= y <= 50):
            return None
        points.append((x, y))
    if any(_orient(points[a], points[b], points[c]) <= 0
           for a, b, c in combinations(range(n), 3)):
        return None
    for a, b, c, d in combinations(range(n), 4):
        if _incircle(points[a], points[b], points[c], points[d]) == 0:
            return None

    diagonal_list = _diagonals(n)
    if len(diagonal_list) > MAX_DIAGONALS:
        return None
    pair_to_bit = {pair: bit for bit, pair in enumerate(diagonal_list)}
    count_at = 1 + 2 * n
    diagonal_count = values[count_at]
    if diagonal_count != n - 3:
        return None
    seed = []
    previous = None
    seed_mask = 0
    first_edge = count_at + 1
    for at in range(diagonal_count):
        u, v = values[first_edge + 2 * at:first_edge + 2 * at + 2]
        pair = (u, v)
        if not (0 <= u < v < n) or pair not in pair_to_bit or (previous is not None and pair <= previous):
            return None
        seed.append(pair)
        previous = pair
        seed_mask |= 1 << pair_to_bit[pair]
    if any(_crosses(seed[i], seed[j]) for i in range(len(seed)) for j in range(i + 1, len(seed))):
        return None
    parsed = (n, points, diagonal_list, pair_to_bit, seed_mask)
    if not _is_delaunay_seed(parsed):
        return None
    return parsed


def _is_delaunay_seed(parsed):
    n, points, diagonal_list, pair_to_bit, seed_mask = parsed
    triangles = _triangles(seed_mask, n, diagonal_list, pair_to_bit)
    if len(triangles) != n - 2:
        return False
    for a, b, c in triangles:
        for d in range(n):
            if d not in (a, b, c) and _incircle(points[a], points[b], points[c], points[d]) > 0:
                return False
    return True


def _flip(mask, edge_index, parsed):
    n, points, diagonal_list, pair_to_bit, _ = parsed
    u, v = diagonal_list[edge_index]
    adjacency = [0] * n
    for vertex in range(n):
        successor = (vertex + 1) % n
        adjacency[vertex] |= 1 << successor
        adjacency[successor] |= 1 << vertex
    for bit, (a, b) in enumerate(diagonal_list):
        if mask & (1 << bit):
            adjacency[a] |= 1 << b
            adjacency[b] |= 1 << a
    common = adjacency[u] & adjacency[v]
    neighbors = [w for w in range(n) if common & (1 << w)]
    if len(neighbors) != 2:
        return None
    c = next((w for w in neighbors if u < w < v), None)
    if c is None:
        return None
    d = neighbors[0] if neighbors[1] == c else neighbors[1]
    opposite = (c, d) if c < d else (d, c)
    opposite_bit = pair_to_bit.get(opposite)
    if opposite_bit is None:
        return None
    return (mask & ~(1 << edge_index)) | (1 << opposite_bit)


def _parent(mask, parsed):
    _, points, diagonal_list, _, _ = parsed
    for edge_index, (u, v) in enumerate(diagonal_list):
        if (mask & (1 << edge_index)) == 0:
            continue
        candidate = _flip(mask, edge_index, parsed)
        if candidate is None:
            continue
        # The unique opposite vertex on the u-to-v interval determines the
        # counterclockwise triangle whose circumcircle tests the other vertex.
        n = parsed[0]
        adjacency = [0] * n
        for vertex in range(n):
            successor = (vertex + 1) % n
            adjacency[vertex] |= 1 << successor
            adjacency[successor] |= 1 << vertex
        for bit, (a, b) in enumerate(diagonal_list):
            if mask & (1 << bit):
                adjacency[a] |= 1 << b
                adjacency[b] |= 1 << a
        common = adjacency[u] & adjacency[v]
        neighbors = [w for w in range(n) if common & (1 << w)]
        if len(neighbors) != 2:
            continue
        c = next((w for w in neighbors if u < w < v), None)
        if c is None:
            continue
        d = neighbors[0] if neighbors[1] == c else neighbors[1]
        if _incircle(points[u], points[c], points[v], points[d]) > 0:
            return candidate
    return None


def _reverse_search_count(parsed):
    n, _, diagonal_list, _, seed_mask = parsed
    count = 1
    stack = [[seed_mask, 0]]
    while stack:
        state, next_edge = stack[-1]
        if next_edge >= len(diagonal_list):
            stack.pop()
            continue
        stack[-1][1] += 1
        if (state & (1 << next_edge)) == 0:
            continue
        child = _flip(state, next_edge, parsed)
        if child is not None and _parent(child, parsed) == state:
            count += 1
            if count > MAX_TRIANGULATIONS:
                return -1
            stack.append([child, 0])
    return count


def expected_result(values):
    parsed = _parse(values)
    if parsed is None:
        return -1
    return _reverse_search_count(parsed)
