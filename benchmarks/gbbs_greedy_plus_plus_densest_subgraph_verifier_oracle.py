"""Independent active-set verifier for GBBS GreedyPlusPlus density output."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_NODES = 16
MIN_NODES = 10
MAX_EDGES = 64
MAX_PARSEABLE_INPUT_LENGTH = 132
INVALID_RESULT = -1e300


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int
                                             or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    n, m = values[:2]
    if not MIN_NODES <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return INVALID_RESULT
    edges = []
    seen = set()
    for offset in range(2, len(values), 2):
        edge = (values[offset], values[offset + 1])
        u, v = edge
        if not 0 <= u < v < n or edge in seen:
            return INVALID_RESULT
        seen.add(edge)
        edges.append(edge)

    load = [0] * n
    for u, v in edges:
        load[u] += 1
        load[v] += 1
    best = 0.0
    for _round in range(20):
        active = set(range(n))
        residual = load.copy()
        order = []
        while active:
            level = min(residual[vertex] for vertex in active)
            shell = sorted(vertex for vertex in active if residual[vertex] == level)
            order.extend(shell)
            active.difference_update(shell)
            for vertex in active:
                removed = sum((vertex, other) in seen or (other, vertex) in seen
                              for other in shell)
                residual[vertex] = max(residual[vertex] - removed, level)
        position = [0] * n
        for rank, vertex in enumerate(order):
            position[vertex] = rank
        later_counts = [0] * n
        for u, v in edges:
            if position[u] < position[v]:
                later_counts[u] += 1
            else:
                later_counts[v] += 1
        density_above = [2 * later_counts[vertex] for vertex in range(n)]
        for vertex in range(n):
            load[vertex] += later_counts[vertex]
        suffix_sum = 0
        for index in range(n - 1, -1, -1):
            suffix_sum += density_above[order[index]]
            score = suffix_sum / (n - index)
            if score > best:
                best = score
    return best if math.isfinite(best) else INVALID_RESULT
