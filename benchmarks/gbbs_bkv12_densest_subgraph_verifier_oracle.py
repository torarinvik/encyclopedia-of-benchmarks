"""Independent active-induced-graph verifier for the GBBS BKV12 profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 130
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
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return INVALID_RESULT
    edges = []
    seen = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or (u, v) in seen:
            return INVALID_RESULT
        seen.add((u, v))
        edges.append((u, v))

    active = set(range(n))
    best = 0.0
    while active:
        induced = [(u, v) for u, v in edges if u in active and v in active]
        density = (2 * len(induced)) / len(active)
        if density > best:
            best = density
        degree = {v: 0 for v in active}
        for u, v in induced:
            degree[u] += 1
            degree[v] += 1
        # Equivalent exact form of D[v] <= 1.001 * average_degree.
        removed = {v for v in active
                   if 1000 * degree[v] * len(active) <= 1001 * 2 * len(induced)}
        if not removed:
            return INVALID_RESULT
        active.difference_update(removed)
    return best if math.isfinite(best) else INVALID_RESULT
