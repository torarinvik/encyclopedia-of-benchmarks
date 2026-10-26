"""Source-stage oracle for the bounded GBBS Barenboim-Elkin order profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 20
MAX_EDGES = 190
MAX_INPUT_LENGTH = 382
MAX_OUTPUT_BYTES = 160


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
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


def _density_threshold_cutoff(adjacency: list[list[bool]], degree: list[int]) -> int:
    n = len(degree)
    alive = [True] * n
    remaining = n
    best_num, best_den = 0, 1
    while remaining:
        total = sum(degree[v] for v in range(n) if alive[v])
        if total * best_den > best_num * remaining:
            best_num, best_den = total, remaining
        # WorkEfficientDensestSubgraph is called with the launcher epsilon .1.
        removed = [v for v in range(n) if alive[v]
                   and 10 * degree[v] * remaining <= 11 * total]
        if not removed:
            return 1
        for vertex in removed:
            alive[vertex] = False
        remaining -= len(removed)
        for vertex in range(n):
            if alive[vertex]:
                degree[vertex] -= sum(adjacency[vertex][u] for u in removed)
    cutoff = (best_num + 10 * best_den - 1) // (10 * best_den)
    return max(cutoff, 1)


def _order(adjacency: list[list[bool]], degree: list[int], cutoff: int) -> list[int]:
    n = len(degree)
    alive = [True] * n
    order: list[int] = []
    while len(order) < n:
        shell = [v for v in range(n) if alive[v] and degree[v] < cutoff]
        if not shell:
            # The pinned code forces one removal when its low-degree batch is empty.
            shell = [next(v for v in range(n) if alive[v])]
        for vertex in shell:
            alive[vertex] = False
            order.append(vertex)
        for vertex in range(n):
            if alive[vertex]:
                degree[vertex] -= sum(adjacency[vertex][u] for u in shell)
    return order


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, adjacency, degree = parsed
    cutoff = _density_threshold_cutoff(adjacency, degree.copy())
    order = _order(adjacency, degree, cutoff)
    ranks = [0] * n
    for rank, vertex in enumerate(order):
        ranks[vertex] = rank
    output = b"".join(struct.pack("<q", rank) for rank in ranks)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
