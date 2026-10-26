"""Primary oracle for the bounded insertion phase of the two-level matcher."""

MAX_INPUT_LENGTH = 55
MAX_OUTPUT_ELEMENTS = 19
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS


def _simulate(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(not isinstance(x, int) for x in values):
        return None
    n, q = values[:2]
    if n not in (4, 9) or not 0 <= q <= 24 or len(values) < 3 + 2*q:
        return None
    pos = 2
    graph = [[False]*n for _ in range(n)]
    seen_edges = set()
    edges = []
    for _ in range(q):
        u, v = values[pos:pos+2]
        pos += 2
        if not 0 <= u < v < n or (u, v) in seen_edges:
            return None
        seen_edges.add((u, v))
        edges.append((u, v))
    if pos >= len(values):
        return None
    r = values[pos]
    pos += 1
    if r < 0 or len(values) != pos + r:
        return None
    ranks = values[pos:]
    if any(x < 0 or x >= n for x in ranks):
        return None

    threshold = int(n**0.5)
    level = [0]*n
    mate = [-1]*n
    rank_pos = 0

    def owned(u):
        result = []
        for v in range(n):
            if not graph[u][v]:
                continue
            if level[u] == 0 and level[v] == 0:
                result.append(v)
            elif level[u] > level[v] or (level[u] == level[v] == 1 and u < v):
                result.append(v)
        return result

    def rematch_free_low(z):
        if z < 0 or level[z] != 0 or mate[z] >= 0:
            return
        for w in range(n):
            if graph[z][w] and level[w] == 0 and mate[w] < 0:
                mate[z] = w
                mate[w] = z
                return

    def promote(u):
        nonlocal rank_pos
        candidates = owned(u)
        if not candidates:
            return False
        if rank_pos >= len(ranks) or ranks[rank_pos] >= len(candidates):
            return False
        y = candidates[ranks[rank_pos]]
        rank_pos += 1
        w, x = mate[u], mate[y]
        if w >= 0:
            mate[w] = -1
            mate[u] = -1
        if x >= 0:
            mate[x] = -1
            mate[y] = -1
        level[u] = level[y] = 1
        mate[u], mate[y] = y, u
        for z in sorted({w, x}):
            rematch_free_low(z)
        return True

    for u, v in edges:
        graph[u][v] = graph[v][u] = True
        if level[u] == 1 or level[v] == 1:
            continue
        if mate[u] < 0 and mate[v] < 0:
            mate[u], mate[v] = v, u
        du, dv = len(owned(u)), len(owned(v))
        candidate = u if du > dv or (du == dv and u < v) else v
        if len(owned(candidate)) >= threshold:
            if not promote(candidate):
                return None
    if rank_pos != len(ranks):
        return None
    return n, level, mate


def expected_output(values, capacity=None, output_is_null=False):
    state = _simulate(values)
    if state is None:
        return -1, b""
    n, levels, mate = state
    output = b"".join(int(x).to_bytes(8, "little", signed=True) for x in (n, *levels, *mate))
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output


def evaluate(values):
    return expected_output(values)
