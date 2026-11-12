"""Independent exhaustive edge-subset oracle for small graph Steiner trees."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 14
MAX_TERMINALS = 5
MAX_INPUT_LENGTH = 50


def _valid(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int, int]], list[int]] | None:
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    for value in values:
        if type(value) is not int or value < -(1 << 63) or value >= (1 << 63):
            return None
    n, m, k = values[0], values[1], values[2]
    if n < 1 or n > MAX_VERTICES or m < 0 or m > MAX_EDGES or k < 1 or k > MAX_TERMINALS or k > n:
        return None
    if m > n * (n - 1) // 2 or len(values) != 3 + k + 3 * m:
        return None
    terminals = [values[3 + i] for i in range(k)]
    if len(set(terminals)) != k or any(v < 0 or v >= n for v in terminals):
        return None
    edges: list[tuple[int, int, int]] = []
    identifiers: set[int] = set()
    pos = 3 + k
    for _ in range(m):
        a, b, weight = values[pos], values[pos + 1], values[pos + 2]
        pos += 3
        if a < 0 or b >= n or a >= b or weight < 0 or weight > 1000:
            return None
        edge_id = a * n + b
        if edge_id in identifiers:
            return None
        identifiers.add(edge_id)
        edges.append((a, b, weight))
    return n, edges, terminals


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _valid(values)
    if parsed is None:
        return -1
    n, edges, terminals = parsed
    best: int | None = None
    for selected in range(1 << len(edges)):
        cost = 0
        parent = list(range(n))

        def find(vertex: int) -> int:
            while parent[vertex] != vertex:
                parent[vertex] = parent[parent[vertex]]
                vertex = parent[vertex]
            return vertex

        for edge_index, (u, v, weight) in enumerate(edges):
            if selected & (1 << edge_index):
                cost += weight
                if best is not None and cost >= best:
                    break
                a, b = find(u), find(v)
                if a != b:
                    parent[a] = b
        else:
            root = find(terminals[0])
            if all(find(vertex) == root for vertex in terminals[1:]):
                if best is None or cost < best:
                    best = cost
    return -2 if best is None else best
