"""Bounded deterministic adaptive bottom-up graph-cut merge profile."""

INVALID_RESULT = -1
MAX_VERTICES = 8
MAX_BOUNDARY_RECORDS = 16
MAX_BLOCKS = 4
MAX_CAPACITY = 7
MAX_VALID_INPUT_LENGTH = 91
MAX_PARSEABLE_INPUT_LENGTH = 92
MAX_RESULT = 56


def _parse(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, block_count = values[:3]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= m <= MAX_BOUNDARY_RECORDS
            or not 1 <= block_count <= min(n, MAX_BLOCKS)
            or len(values) != 3 + 3 * n + 4 * m):
        return None
    block_ids = list(values[3:3 + n])
    if (any(not 0 <= b < block_count for b in block_ids)
            or set(block_ids) != set(range(block_count))):
        return None
    source_caps = list(values[3 + n:3 + 2 * n])
    sink_caps = list(values[3 + 2 * n:3 + 3 * n])
    if any(not 0 <= c <= MAX_CAPACITY for c in source_caps + sink_caps):
        return None
    edges = []
    offset = 3 + 3 * n
    for i in range(m):
        u, v, uv, vu = values[offset + 4 * i:offset + 4 * i + 4]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= uv <= MAX_CAPACITY or not 0 <= vu <= MAX_CAPACITY):
            return None
        edges.append((u, v, uv, vu))
    return n, block_count, block_ids, source_caps, sink_caps, edges


def _augment_to_maximum(residual, source, sink, ordinary_count, allowed):
    """Deterministic Edmonds–Karp augmentation restricted to one merged group."""
    total = 0
    size = ordinary_count + 2
    while True:
        parent = [-1] * size
        parent[source] = source
        queue = [source]
        head = 0
        while head < len(queue) and parent[sink] == -1:
            u = queue[head]
            head += 1
            for v in range(size):
                if (parent[v] != -1 or residual[u][v] <= 0 or v == source
                        or u == sink):
                    continue
                if v < ordinary_count and not allowed[v]:
                    continue
                if u < ordinary_count and not allowed[u]:
                    continue
                parent[v] = u
                queue.append(v)
                if v == sink:
                    break
        if parent[sink] == -1:
            return total
        amount = MAX_CAPACITY * ordinary_count
        v = sink
        while v != source:
            u = parent[v]
            amount = min(amount, residual[u][v])
            v = u
        v = sink
        while v != source:
            u = parent[v]
            residual[u][v] -= amount
            residual[v][u] += amount
            v = u
        total += amount


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, block_count, block_ids, source_caps, sink_caps, edges = parsed
    source, sink = n, n + 1
    residual = [[0] * (n + 2) for _ in range(n + 2)]
    for u in range(n):
        residual[source][u] += source_caps[u]
        residual[u][sink] += sink_caps[u]

    boundary = []
    for u, v, uv, vu in edges:
        if block_ids[u] == block_ids[v]:
            residual[u][v] += uv
            residual[v][u] += vu
        elif uv or vu:
            a, b = sorted((block_ids[u], block_ids[v]))
            boundary.append((a, b, u, v, uv, vu, False))

    # Phase one: each disjoint block gets its own restricted max-flow solve.
    for block in range(block_count):
        allowed = [block_ids[u] == block for u in range(n)]
        _augment_to_maximum(residual, source, sink, n, allowed)

    # Tag phase-one residual search regions: source tree, sink tree, or unvisited.
    tags = [0] * n
    for block in range(block_count):
        allowed = [block_ids[u] == block for u in range(n)]
        source_seen = [False] * (n + 2)
        source_seen[source] = True
        queue = [source]
        for u in queue:
            for v in range(n + 2):
                if (not source_seen[v] and residual[u][v] > 0
                        and (v >= n or allowed[v]) and (u >= n or allowed[u])):
                    source_seen[v] = True
                    queue.append(v)

        sink_seen = [False] * (n + 2)
        sink_seen[sink] = True
        queue = [sink]
        for v in queue:
            for u in range(n + 2):
                if (not sink_seen[u] and residual[u][v] > 0
                        and (u >= n or allowed[u]) and (v >= n or allowed[v])):
                    sink_seen[u] = True
                    queue.append(u)
        for u in range(n):
            if allowed[u]:
                tags[u] = 1 if source_seen[u] else (2 if sink_seen[u] else 0)

    potentials = {}
    for a, b, u, v, uv, vu, _ in boundary:
        key = (a, b)
        potentials[key] = potentials.get(key, 0)
        if tags[u] != tags[v]:
            potentials[key] += int(uv > 0) + int(vu > 0)
    ordered_pairs = sorted(potentials, key=lambda pair: (-potentials[pair], pair[0], pair[1]))

    # Phase two: deterministic serial emulation of adaptive bottom-up merging.
    parent = list(range(block_count))

    def find(block):
        while parent[block] != block:
            parent[block] = parent[parent[block]]
            block = parent[block]
        return block

    enabled = [False] * len(boundary)
    for a, b in ordered_pairs:
        root_a, root_b = find(a), find(b)
        if root_a == root_b:
            continue
        root = min(root_a, root_b)
        other = max(root_a, root_b)
        parent[other] = root
        # Restore every boundary arc that is now internal to the merged group.
        for i, (ba, bb, u, v, uv, vu, was_enabled) in enumerate(boundary):
            if not was_enabled and find(ba) == find(bb):
                residual[u][v] += uv
                residual[v][u] += vu
                boundary[i] = (ba, bb, u, v, uv, vu, True)
                enabled[i] = True
        allowed = [find(block_ids[u]) == root for u in range(n)]
        _augment_to_maximum(residual, source, sink, n, allowed)

    return sum(source_caps[u] - residual[source][u] for u in range(n))

