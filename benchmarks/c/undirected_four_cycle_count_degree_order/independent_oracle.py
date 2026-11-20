"""Canonical four-vertex cycle enumerator, independent of degree orientation."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations, permutations

from .primary_oracle import (
    INVALID_RESULT,
    MAX_M,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: set[tuple[int, int]] = set()
    previous: tuple[int, int] | None = None
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        edge = (u, v)
        if (not 0 <= u < v < n or edge in edges
                or (previous is not None and edge <= previous)):
            return None
        edges.add(edge)
        previous = edge
    return n, edges


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, edges = parsed
    total = 0
    for vertices in combinations(range(n), 4):
        first, *rest = vertices
        # The smallest vertex is fixed first. Requiring the first neighbor to
        # be smaller than the last chooses one orientation per undirected cycle.
        for cycle_tail in permutations(rest):
            if cycle_tail[0] > cycle_tail[-1]:
                continue
            cycle = (first, *cycle_tail)
            cycle_edges = tuple(
                (min(cycle[i], cycle[(i + 1) % 4]),
                 max(cycle[i], cycle[(i + 1) % 4]))
                for i in range(4)
            )
            if all(edge in edges for edge in cycle_edges):
                total += 1
    return total
