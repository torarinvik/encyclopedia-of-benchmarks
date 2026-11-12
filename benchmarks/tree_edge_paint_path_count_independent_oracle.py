"""Independent direct-path oracle for dynamic tree edge painting."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

try:
    from .tree_edge_paint_path_count_oracle import (
        INVALID_RESULT,
        MAX_N,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_QUERIES,
    )
except ImportError:  # Direct execution from the benchmarks directory.
    from tree_edge_paint_path_count_oracle import (
        INVALID_RESULT,
        MAX_N,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_QUERIES,
    )


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_QUERIES:
        return INVALID_RESULT
    edge_count = n - 1
    if len(values) != 2 + 2 * edge_count + 3 * q:
        return INVALID_RESULT
    edges: list[tuple[int, int]] = []
    parent = list(range(n))

    def find(node: int) -> int:
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    cursor = 2
    for edge_id in range(edge_count):
        u, v = values[cursor], values[cursor + 1]
        cursor += 2
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return INVALID_RESULT
        left, right = find(u), find(v)
        if left == right:
            return INVALID_RESULT
        parent[left] = right
        edges.append((u, v))
        adjacency[u].append((v, edge_id))
        adjacency[v].append((u, edge_id))
    if any(find(node) != find(0) for node in range(n)):
        return INVALID_RESULT

    operations = []
    for _ in range(q):
        kind, a, b = values[cursor], values[cursor + 1], values[cursor + 2]
        cursor += 3
        if kind == 0:
            if not 0 <= a < edge_count or b != 0:
                return INVALID_RESULT
        elif kind == 1:
            if not 0 <= a < n or not 0 <= b < n:
                return INVALID_RESULT
        else:
            return INVALID_RESULT
        operations.append((kind, a, b))

    painted = [False] * edge_count
    total = 0
    for kind, a, b in operations:
        if kind == 0:
            painted[a] = True
            continue
        previous = [-1] * n
        previous_edge = [-1] * n
        previous[a] = a
        queue = deque([a])
        while queue and previous[b] == -1:
            node = queue.popleft()
            for neighbor, edge_id in adjacency[node]:
                if previous[neighbor] == -1:
                    previous[neighbor] = node
                    previous_edge[neighbor] = edge_id
                    queue.append(neighbor)
        node = b
        count = 0
        while node != a:
            edge_id = previous_edge[node]
            count += int(painted[edge_id])
            node = previous[node]
        total += count
    return total
