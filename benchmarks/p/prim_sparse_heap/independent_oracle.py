"""Kruskal/DSU reference for the sparse-frontier Prim profile."""

from __future__ import annotations

from collections.abc import Sequence

LIMIT_VERTICES = 64
LIMIT_EDGES = 4096
LIMIT_WEIGHT = 2147483647
WORD_MIN = -(1 << 63)
WORD_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 2:
        return -2
    if any(type(value) is not int or value < WORD_MIN or value > WORD_MAX for value in values):
        return -2
    n, m = values[0], values[1]
    if n < 0 or n > LIMIT_VERTICES or m < 0 or m > LIMIT_EDGES:
        return -2
    if len(values) != 2 + 3 * m or len(values) > 2 + 3 * LIMIT_EDGES:
        return -2
    if n == 0:
        return 0 if m == 0 else -2
    edges = []
    for offset in range(2, len(values), 3):
        a, b, weight = values[offset], values[offset + 1], values[offset + 2]
        if a < 0 or a >= n or b < 0 or b >= n or weight < 0 or weight > LIMIT_WEIGHT:
            return -2
        if a != b:
            edges.append((weight, min(a, b), max(a, b)))

    parent = list(range(n))
    size = [1] * n

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    total = 0
    selected = 0
    for weight, a, b in sorted(edges):
        root_a, root_b = find(a), find(b)
        if root_a == root_b:
            continue
        if size[root_a] < size[root_b]:
            root_a, root_b = root_b, root_a
        parent[root_b] = root_a
        size[root_a] += size[root_b]
        total += weight
        selected += 1
        if selected == n - 1:
            break
    return total if selected == n - 1 else -1
