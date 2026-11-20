"""Degree-order two-path counter for simple undirected four-cycles."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_M = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_CYCLES = 3 * (MAX_N * (MAX_N - 1) * (MAX_N - 2) * (MAX_N - 3) // 24)
WORKSPACE_BYTES = 8192
INVALID_RESULT = -1


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
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    if len(values) != 2 + 2 * m:
        return None
    adjacency = [[False] * n for _ in range(n)]
    previous: tuple[int, int] | None = None
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        edge = (u, v)
        if (not 0 <= u < v < n
                or (previous is not None and edge <= previous)):
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
    degree = [len(row) for row in neighbors]
    order = sorted(range(n), key=lambda vertex: (degree[vertex], vertex))
    rank = [0] * n
    for position, vertex in enumerate(order):
        rank[vertex] = position

    total = 0
    counts = [0] * n
    for pivot in order:
        pivot_rank = rank[pivot]
        for middle in neighbors[pivot]:
            if rank[middle] >= pivot_rank:
                continue
            for opposite in neighbors[middle]:
                if rank[opposite] < pivot_rank:
                    total += counts[opposite]
                    counts[opposite] += 1
        for vertex in range(n):
            counts[vertex] = 0
    return total
