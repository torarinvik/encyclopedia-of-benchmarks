"""Canonical DFS cycle enumerator, independent of subset-path DP."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
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
    if not 1 <= n <= MAX_N or not 0 <= m <= n * (n - 1) // 2:
        return None
    if len(values) != 2 + 2 * m:
        return None
    adjacency = [[False] * n for _ in range(n)]
    previous: tuple[int, int] | None = None
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        edge = (u, v)
        if not 0 <= u < v < n or (previous is not None and edge <= previous):
            return None
        adjacency[u][v] = adjacency[v][u] = True
        previous = edge
    return n, adjacency


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency = parsed
    neighbors = [[v for v in range(n) if adjacency[u][v]] for u in range(n)]
    total = 0
    for start in range(n):
        path = [start]
        visited = 1 << start

        def visit(current: int) -> None:
            nonlocal total, visited
            for nxt in neighbors[current]:
                if nxt == start:
                    if len(path) >= 3 and path[1] < path[-1]:
                        total += 1
                elif nxt > start and not (visited & (1 << nxt)):
                    visited |= 1 << nxt
                    path.append(nxt)
                    visit(nxt)
                    path.pop()
                    visited ^= 1 << nxt

        visit(start)
    return total
