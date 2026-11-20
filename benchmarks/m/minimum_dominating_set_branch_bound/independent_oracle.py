"""Independent subset-size enumeration for minimum dominating set."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

from .primary_oracle import INVALID_RESULT, MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VERTICES


def verify_candidate(values: Sequence[int] | None, input_is_null: bool = False,
                     input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return INVALID_RESULT
    if m > n * (n - 1) // 2:
        return INVALID_RESULT
    if input_length != 2 + 2 * m:
        return INVALID_RESULT

    adjacency = [0] * n
    seen: set[tuple[int, int]] = set()
    for edge in range(m):
        u, v = values[2 + 2 * edge:4 + 2 * edge]
        edge_key = (min(u, v), max(u, v))
        if not 0 <= u < n or not 0 <= v < n or u == v or edge_key in seen:
            return INVALID_RESULT
        seen.add(edge_key)
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u
    closed = [adjacency[v] | (1 << v) for v in range(n)]
    full = (1 << n) - 1
    for size in range(n + 1):
        for chosen in combinations(range(n), size):
            covered = 0
            for vertex in chosen:
                covered |= closed[vertex]
            if covered == full:
                return size
    return n
