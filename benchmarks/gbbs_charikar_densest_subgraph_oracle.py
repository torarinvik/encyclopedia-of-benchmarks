"""Deterministic shell-peeling oracle for the bounded GBBS Charikar profile."""
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
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return INVALID_RESULT
    adjacent = [[False] * n for _ in range(n)]
    degree = [0] * n
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or adjacent[u][v]:
            return INVALID_RESULT
        adjacent[u][v] = adjacent[v][u] = True
        degree[u] += 1
        degree[v] += 1

    alive = [True] * n
    order: list[int] = []
    shell_level = 0
    while len(order) < n:
        shell_level = min(degree[v] for v in range(n) if alive[v])
        while True:
            shell = [v for v in range(n) if alive[v] and degree[v] == shell_level]
            if not shell:
                break
            for v in shell:
                alive[v] = False
                order.append(v)
            for v in range(n):
                if alive[v]:
                    removed = sum(adjacent[v][u] for u in shell)
                    degree[v] = max(degree[v] - removed, shell_level)

    position = [0] * n
    for rank, vertex in enumerate(order):
        position[vertex] = rank
    best = 0.0
    for start in range(n):
        edges = sum(
            position[u] >= start and position[v] >= start
            for u in range(n) for v in range(u + 1, n) if adjacent[u][v]
        )
        score = (2.0 * edges) / float(n - start)
        if score > best:
            best = score
    return best if math.isfinite(best) else INVALID_RESULT
