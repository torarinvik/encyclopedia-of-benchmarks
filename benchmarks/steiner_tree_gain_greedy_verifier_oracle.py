"""Independent verifier using path enumeration and exhaustive forest selection."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 37


def _components(n: int, edges: set[tuple[int, int]]) -> tuple[list[int], list[int]]:
    parent = list(range(n))

    def root(x: int) -> int:
        while parent[x] != x:
            x = parent[x]
        return x

    for u, v in edges:
        a, b = root(u), root(v)
        if a != b:
            parent[b] = a
    return parent, [root(i) for i in range(n)]


def _forest_optimum(n: int, w: list[list[int]], h: set[tuple[int, int]]) -> tuple[int, list[tuple[int, int]]]:
    edges = sorted(h, key=lambda e: (w[e[0]][e[1]], e[0], e[1]))
    _, original = _components(n, h)
    best_cost: int | None = None
    best_keys: tuple[tuple[int, int, int], ...] | None = None
    best_edges: list[tuple[int, int]] = []
    for subset in range(1 << len(edges)):
        parent = list(range(n))

        def root(x: int) -> int:
            while parent[x] != x:
                x = parent[x]
            return x

        chosen: list[tuple[int, int]] = []
        cost = 0
        acyclic = True
        for i, (u, v) in enumerate(edges):
            if subset & (1 << i):
                a, b = root(u), root(v)
                if a == b:
                    acyclic = False
                    break
                parent[b] = a
                chosen.append((u, v))
                cost += w[u][v]
        if not acyclic:
            continue
        if any(root(u) != root(v) for u, v in h):
            continue
        keys = tuple((w[u][v], u, v) for u, v in chosen)
        if best_cost is None or cost < best_cost or (cost == best_cost and keys < best_keys):
            best_cost, best_keys, best_edges = cost, keys, chosen
    return (best_cost or 0), best_edges


def _metric_mst(vertices: list[int], w: list[list[int]]) -> int:
    if len(vertices) <= 1:
        return 0
    connected = {vertices[0]}
    total = 0
    while len(connected) < len(vertices):
        cost, u, v = min((w[a][b], a, b) for a in connected for b in vertices if b not in connected)
        total += cost
        connected.add(v)
    return total


def _contracted_mst(n: int, mask: int, w: list[list[int]], h: set[tuple[int, int]]) -> int:
    _, comp = _components(n, h)
    roots: list[int] = []
    for v in range(n):
        if mask & (1 << v) and comp[v] not in roots:
            roots.append(comp[v])
    if len(roots) <= 1:
        return 0
    members = [[v for v in range(n) if comp[v] == r] for r in roots]

    def shortest(start: int, goal: int) -> int:
        best = 1 << 60

        def walk(at: int, seen: int, cost: int) -> None:
            nonlocal best
            if cost >= best:
                return
            if at == goal:
                best = cost
                return
            for nxt in range(n):
                if seen & (1 << nxt):
                    continue
                step = 0 if (min(at, nxt), max(at, nxt)) in h else w[at][nxt]
                walk(nxt, seen | (1 << nxt), cost + step)

        walk(start, 1 << start, 0)
        return best

    q = [[0] * len(roots) for _ in roots]
    for i in range(len(roots)):
        for j in range(i + 1, len(roots)):
            q[i][j] = q[j][i] = min(shortest(a, b) for a in members[i] for b in members[j])
    selected = {0}
    total = 0
    while len(selected) < len(roots):
        weight, vertex = min((q[a][b], b) for a in selected for b in range(len(roots)) if b not in selected)
        total += weight
        selected.add(vertex)
    return total


def _parse(vals: Sequence[int] | None, input_length: int | None, input_is_null: bool):
    if input_is_null or vals is None or not isinstance(vals, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(vals) or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return None
    if not 4 <= len(vals) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in vals):
        return None
    n, mask, count = vals[:3]
    if not 2 <= n <= 4 or mask <= 0 or mask >> n or not 1 <= count <= 4:
        return None
    terms = [v for v in range(n) if mask & (1 << v)]
    if len(terms) < 2:
        return None
    w = [[0] * n for _ in range(n)]
    at = 3
    for a in range(n):
        for b in range(a + 1, n):
            if at >= len(vals) or not 0 <= vals[at] <= 1000:
                return None
            w[a][b] = w[b][a] = vals[at]
            at += 1
    if any(w[a][b] > w[a][c] + w[c][b] for a in range(n) for b in range(n) for c in range(n)):
        return None
    family: list[list[tuple[int, int]]] = []
    union_edges: set[tuple[int, int]] = set()
    for _ in range(count):
        if at >= len(vals):
            return None
        ec = vals[at]
        at += 1
        if not 1 <= ec <= n - 1 or at + 2 * ec > len(vals):
            return None
        edges: list[tuple[int, int]] = []
        degree = [0] * n
        parent = list(range(n))

        def root(x: int) -> int:
            while parent[x] != x:
                x = parent[x]
            return x

        for _edge in range(ec):
            u, v = vals[at], vals[at + 1]
            at += 2
            if not (0 <= u < n and 0 <= v < n) or u == v:
                return None
            e = (min(u, v), max(u, v))
            if e in edges or root(u) == root(v):
                return None
            parent[root(u)] = root(v)
            edges.append(e)
            union_edges.add(e)
            degree[u] += 1
            degree[v] += 1
        verts = [v for v in range(n) if degree[v]]
        if len(verts) != ec + 1 or len({root(v) for v in verts}) != 1:
            return None
        leaves = [v for v in verts if degree[v] == 1]
        if len(leaves) not in (2, 3) or any(not (mask & (1 << v)) for v in leaves) or any(
                mask & (1 << v) and degree[v] != 1 for v in verts):
            return None
        family.append(edges)
    if at != len(vals):
        return None
    _, cc = _components(n, union_edges)
    if len({cc[v] for v in terms}) != 1:
        return None
    return n, mask, w, family


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool or capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    n, mask, w, family = parsed
    baseline = _metric_mst([v for v in range(n) if mask & (1 << v)], w)
    h: set[tuple[int, int]] = set()
    chosen: set[int] = set()
    while True:
        _, before_cc = _components(n, h)
        before_groups = {before_cc[v] for v in range(n) if mask & (1 << v)}
        if len(before_groups) <= 1:
            break
        before = len(before_groups)
        pick = None
        pick_gain = None
        for i, comp in enumerate(family):
            if i in chosen:
                continue
            trial = h | set(comp)
            _, after_cc = _components(n, trial)
            if len({after_cc[v] for v in range(n) if mask & (1 << v)}) >= before:
                continue
            mst_h, _ = _forest_optimum(n, w, trial)
            gain = baseline - _contracted_mst(n, mask, w, trial) - mst_h
            if pick_gain is None or gain > pick_gain:
                pick, pick_gain = i, gain
        if pick is None:
            return -1, b""
        chosen.add(pick)
        h.update(family[pick])
    cost, edges = _forest_optimum(n, w, h)
    words = [1, cost, len(edges)] + [x for edge in edges for x in edge]
    payload = b"".join(struct.pack("<q", x) for x in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
