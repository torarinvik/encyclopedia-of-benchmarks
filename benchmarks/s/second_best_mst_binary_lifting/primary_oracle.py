"""Kruskal and binary-lifting path maxima for the strict second MST."""

MAX_INPUT_LENGTH = 63


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, m = values[:2]
    if not 1 <= n <= 8 or not n - 1 <= m <= 20 or len(values) != 2 + 3 * m:
        return -1
    edges = []
    seen = set()
    for edge_id in range(m):
        u, v, weight = values[2 + 3 * edge_id:5 + 3 * edge_id]
        if not 0 <= u < v < n or not 0 <= weight <= 1_000_000 or (u, v) in seen:
            return -1
        seen.add((u, v))
        edges.append((weight, edge_id, u, v))
    parent = list(range(n))
    def find(vertex):
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex
    tree = [[] for _ in range(n)]
    chosen = set()
    total = 0
    for weight, edge_id, u, v in sorted(edges):
        a, b = find(u), find(v)
        if a != b:
            parent[a] = b
            chosen.add(edge_id)
            total += weight
            tree[u].append((v, weight))
            tree[v].append((u, weight))
    if len(chosen) != n - 1:
        return -1

    def merge(a, b):
        return tuple(sorted(set(a + b), reverse=True)[:2])
    levels = max(1, n.bit_length())
    up = [[0] * n for _ in range(levels)]
    best = [[() for _ in range(n)] for _ in range(levels)]
    depth = [-1] * n
    depth[0] = 0
    queue = [0]
    for u in queue:
        for v, weight in tree[u]:
            if depth[v] < 0:
                depth[v] = depth[u] + 1
                up[0][v] = u
                best[0][v] = (weight,)
                queue.append(v)
    for level in range(1, levels):
        for vertex in range(n):
            middle = up[level - 1][vertex]
            up[level][vertex] = up[level - 1][middle]
            best[level][vertex] = merge(best[level - 1][vertex], best[level - 1][middle])

    def path_weights(u, v):
        found = ()
        if depth[u] < depth[v]:
            u, v = v, u
        difference = depth[u] - depth[v]
        for level in range(levels):
            if difference & (1 << level):
                found = merge(found, best[level][u])
                u = up[level][u]
        if u != v:
            for level in range(levels - 1, -1, -1):
                if up[level][u] != up[level][v]:
                    found = merge(merge(found, best[level][u]), best[level][v])
                    u, v = up[level][u], up[level][v]
            found = merge(merge(found, best[0][u]), best[0][v])
        return found

    increase = None
    for weight, edge_id, u, v in edges:
        if edge_id in chosen:
            continue
        candidates = path_weights(u, v)
        for removed in candidates:
            if removed < weight:
                delta = weight - removed
                increase = delta if increase is None else min(increase, delta)
                break
    return 0 if increase is None else total + increase + 1
