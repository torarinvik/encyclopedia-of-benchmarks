"""Primary integer oracle for the bounded finite-family Steiner-tree greedy profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 4
MAX_COMPONENTS = 4
MAX_INPUT_LENGTH = 37
MAX_OUTPUT_BYTES = 72


def _dsu(n: int):
    parent = list(range(n))

    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a: int, b: int) -> bool:
        a, b = find(a), find(b)
        if a == b:
            return False
        parent[b] = a
        return True

    return parent, find, union


def _mst_edges(n: int, weights: list[list[int]], edges: set[tuple[int, int]]) -> tuple[int, list[tuple[int, int]]]:
    parent, find, union = _dsu(n)
    chosen: list[tuple[int, int]] = []
    cost = 0
    for u, v in sorted(edges, key=lambda e: (weights[e[0]][e[1]], e[0], e[1])):
        if union(u, v):
            chosen.append((u, v))
            cost += weights[u][v]
    return cost, chosen


def _metric_mst(vertices: list[int], weights: list[list[int]]) -> int:
    if len(vertices) <= 1:
        return 0
    used = {vertices[0]}
    best = {v: weights[vertices[0]][v] for v in vertices[1:]}
    total = 0
    while len(used) < len(vertices):
        v = min((x for x in vertices if x not in used), key=lambda x: (best[x], x))
        total += best[v]
        used.add(v)
        for x in vertices:
            if x not in used and weights[v][x] < best[x]:
                best[x] = weights[v][x]
    return total


def _terminal_groups(n: int, terminal_mask: int, h: set[tuple[int, int]]) -> tuple[list[int], list[int]]:
    parent, find, union = _dsu(n)
    for u, v in h:
        union(u, v)
    group_roots: list[int] = []
    terminal_group = [-1] * n
    for v in range(n):
        if terminal_mask & (1 << v):
            root = find(v)
            if root not in group_roots:
                group_roots.append(root)
            terminal_group[v] = group_roots.index(root)
    return group_roots, terminal_group


def _contracted_mst(n: int, terminal_mask: int, weights: list[list[int]],
                    h: set[tuple[int, int]]) -> int:
    parent, find, union = _dsu(n)
    dist = [row[:] for row in weights]
    for u, v in h:
        union(u, v)
        dist[u][v] = dist[v][u] = 0
    for k in range(n):
        for i in range(n):
            for j in range(n):
                through = dist[i][k] + dist[k][j]
                if through < dist[i][j]:
                    dist[i][j] = through
    groups: list[int] = []
    for v in range(n):
        if terminal_mask & (1 << v):
            root = find(v)
            if root not in groups:
                groups.append(root)
    if len(groups) <= 1:
        return 0
    members = [[v for v in range(n) if find(v) == root] for root in groups]
    quotient = [[0] * len(groups) for _ in groups]
    for i in range(len(groups)):
        for j in range(i + 1, len(groups)):
            quotient[i][j] = quotient[j][i] = min(
                dist[u][v] for u in members[i] for v in members[j]
            )
    # Prim on the terminal-bearing contracted components.
    used = {0}
    best = {j: quotient[0][j] for j in range(1, len(groups))}
    total = 0
    while len(used) < len(groups):
        v = min((x for x in range(len(groups)) if x not in used),
                key=lambda x: (best[x], x))
        total += best[v]
        used.add(v)
        for x in range(len(groups)):
            if x not in used and quotient[v][x] < best[x]:
                best[x] = quotient[v][x]
    return total


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int, list[list[int]], list[list[tuple[int, int]]]] | None:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    if (input_length is not None and (type(input_length) is not int or
            input_length != len(values) or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return None
    if not 4 <= len(values) <= MAX_INPUT_LENGTH or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n, mask, count = values[:3]
    if not 2 <= n <= MAX_N or mask <= 0 or mask >> n or not 1 <= count <= MAX_COMPONENTS:
        return None
    terminals = [v for v in range(n) if mask & (1 << v)]
    if len(terminals) < 2:
        return None
    weights = [[0] * n for _ in range(n)]
    at = 3
    for u in range(n):
        for v in range(u + 1, n):
            if at >= len(values) or not 0 <= values[at] <= 1000:
                return None
            weights[u][v] = weights[v][u] = values[at]
            at += 1
    if any(weights[u][v] > weights[u][k] + weights[k][v]
           for u in range(n) for v in range(n) for k in range(n)):
        return None
    family: list[list[tuple[int, int]]] = []
    all_edges: set[tuple[int, int]] = set()
    for _ in range(count):
        if at >= len(values):
            return None
        m = values[at]
        at += 1
        if not 1 <= m <= n - 1 or at + 2 * m > len(values):
            return None
        component: list[tuple[int, int]] = []
        degree = [0] * n
        parent, find, union = _dsu(n)
        for _edge in range(m):
            u, v = values[at], values[at + 1]
            at += 2
            e = (min(u, v), max(u, v))
            if not (0 <= u < n and 0 <= v < n) or u == v or e in component or not union(u, v):
                return None
            component.append(e)
            all_edges.add(e)
            degree[u] += 1
            degree[v] += 1
        endpoints = [v for v in range(n) if degree[v]]
        if len(endpoints) != m + 1 or len({find(v) for v in endpoints}) != 1:
            return None
        leaves = 0
        for v in endpoints:
            if degree[v] == 1:
                if not (mask & (1 << v)):
                    return None
                leaves += 1
            elif mask & (1 << v):
                return None
        if leaves not in (2, 3) or any(degree[v] == 1 and not (mask & (1 << v)) for v in endpoints):
            return None
        family.append(component)
    if at != len(values):
        return None
    parent, find, union = _dsu(n)
    for u, v in all_edges:
        union(u, v)
    if len({find(v) for v in terminals}) != 1:
        return None
    return n, mask, weights, family


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    n, mask, weights, family = parsed
    h: set[tuple[int, int]] = set()
    baseline = _metric_mst([v for v in range(n) if mask & (1 << v)], weights)
    selected: set[int] = set()
    while len(_terminal_groups(n, mask, h)[0]) > 1:
        before = len(_terminal_groups(n, mask, h)[0])
        best_index = -1
        best_gain: int | None = None
        for index, component in enumerate(family):
            if index in selected:
                continue
            trial = h | set(component)
            if len(_terminal_groups(n, mask, trial)[0]) >= before:
                continue
            mst_h, _ = _mst_edges(n, weights, trial)
            gain = baseline - _contracted_mst(n, mask, weights, trial) - mst_h
            if best_gain is None or gain > best_gain:
                best_index, best_gain = index, gain
        if best_index < 0:
            return -1, b""
        selected.add(best_index)
        h.update(family[best_index])
    cost, tree = _mst_edges(n, weights, h)
    words = [1, cost, len(tree)] + [x for edge in tree for x in edge]
    size = len(words) * 8
    if output_is_null or capacity is not None and capacity < size:
        return -2, b""
    return size, b"".join(struct.pack("<q", x) for x in words)
