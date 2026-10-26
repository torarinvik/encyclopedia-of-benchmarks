"""Source-stage oracle for the bounded GBBS BKV12 peeling profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_NODES = 16
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
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
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


def _profile_density(n: int, adjacency: list[list[bool]], degree: list[int]) -> float:
    alive = [True] * n
    remaining = n
    best = 0.0
    while remaining:
        total_degree = sum(degree[v] for v in range(n) if alive[v])
        density = total_degree / remaining
        if density > best:
            best = density
        # The pinned launcher default is epsilon=0.001. Rational comparison
        # avoids language-specific floating threshold ties.
        removed = [v for v in range(n) if alive[v]
                   and 1000 * degree[v] * remaining <= 1001 * total_degree]
        if not removed:
            return INVALID_RESULT
        for vertex in removed:
            alive[vertex] = False
        remaining -= len(removed)
        for u in range(n):
            if not alive[u]:
                continue
            degree[u] -= sum(adjacency[u][v] for v in removed)
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
