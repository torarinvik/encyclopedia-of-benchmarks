"""Source-stage oracle for GBBS GreedyPlusPlus's 20 reweighted passes."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_NODES = 16
MIN_NODES = 10
MAX_EDGES = 64
MAX_INPUT_LENGTH = 130
MAX_PARSEABLE_INPUT_LENGTH = 132
INVALID_RESULT = -1e300


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[:2]
    if not MIN_NODES <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    adjacency = [[False] * n for _ in range(n)]
    degree = [0] * n
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or adjacency[u][v]:
            return None
        adjacency[u][v] = adjacency[v][u] = True
        degree[u] += 1
        degree[v] += 1
    return n, adjacency, degree


def _load_degeneracy_order(adjacency: list[list[bool]], load: list[int]) -> list[int]:
    n = len(load)
    degree = load.copy()
    alive = [True] * n
    order: list[int] = []
    while len(order) < n:
        level = min(degree[v] for v in range(n) if alive[v])
        shell = [v for v in range(n) if alive[v] and degree[v] == level]
        for vertex in shell:
            alive[vertex] = False
            order.append(vertex)
        for vertex in range(n):
            if alive[vertex]:
                removed_neighbors = sum(adjacency[vertex][u] for u in shell)
                degree[vertex] = max(degree[vertex] - removed_neighbors, level)
    return order


def _profile_density(n: int, adjacency: list[list[bool]], load: list[int]) -> float:
    best = 0.0
    for _round in range(20):
        order = _load_degeneracy_order(adjacency, load)
        position = [0] * n
        for rank, vertex in enumerate(order):
            position[vertex] = rank
        density_above = [0] * n
        for vertex in range(n):
            later_neighbors = sum(adjacency[vertex][other]
                                  for other in range(n)
                                  if position[other] > position[vertex])
            density_above[position[vertex]] = 2 * later_neighbors
            load[vertex] += later_neighbors
        suffix_edges = 0
        for index in range(n - 1, -1, -1):
            suffix_edges += density_above[index]
            score = suffix_edges / (n - index)
            if score > best:
                best = score
    return best if math.isfinite(best) else INVALID_RESULT


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int
                                             or input_length != len(values))):
        return INVALID_RESULT
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency, degree = parsed
    return _profile_density(n, adjacency, degree)
