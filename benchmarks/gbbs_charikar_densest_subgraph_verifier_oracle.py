"""Independent edge-list verifier for the bounded Charikar shell profile."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 130
MAX_PARSEABLE_INPUT_LENGTH = 132
INVALID_RESULT = -1e300


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> float:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return INVALID_RESULT
    edges: list[tuple[int, int]] = []
    neighbors = [set() for _ in range(n)]
    for i in range(m):
        u, v = values[2 + 2 * i], values[3 + 2 * i]
        if not 0 <= u < v < n or v in neighbors[u]:
            return INVALID_RESULT
        neighbors[u].add(v)
        neighbors[v].add(u)
        edges.append((u, v))

    active = set(range(n))
    residual = [len(neighbors[v]) for v in range(n)]
    order: list[int] = []
    while active:
        level = min(residual[v] for v in active)
        layer = sorted(v for v in active if residual[v] == level)
        while layer:
            active.difference_update(layer)
            order.extend(layer)
            layer_set = set(layer)
            for vertex in active:
                residual[vertex] = max(residual[vertex] - len(neighbors[vertex] & layer_set), level)
            layer = sorted(v for v in active if residual[v] == level)

    rank = {vertex: index for index, vertex in enumerate(order)}
    best = 0.0
    for start in range(n):
        remaining = n - start
        edge_count = 0
        for u, v in edges:
            if rank[u] >= start and rank[v] >= start:
                edge_count += 1
        best = max(best, 2.0 * float(edge_count) / float(remaining))
    return best if math.isfinite(best) else INVALID_RESULT
