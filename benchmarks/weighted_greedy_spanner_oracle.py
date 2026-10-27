"""Bounded oracle for the weighted greedy (2k-1)-spanner algorithm."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = MAX_N * (MAX_N - 1) // 2
MAX_INPUT_LENGTH = 3 + 3 * MAX_M + 1
MAX_OUTPUT_BYTES = MAX_M
INVALID_RESULT = -1
OUTPUT_ERROR = -2
INF = 1 << 60


def _decode(values: Sequence[int] | None) -> tuple[int, int, int, list[tuple[int, int, int]]] | None:
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, k = values[:3]
    if not 2 <= n <= MAX_N or not 0 <= m <= MAX_M or not 1 <= k <= 3:
        return None
    if len(values) != 3 + 3 * m:
        return None
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(m):
        u, v, weight = values[3 + 3 * index:6 + 3 * index]
        if not 0 <= u < v < n or not 1 <= weight <= 32 or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v, weight))
    return n, m, k, edges


def _dijkstra(n: int, adjacency: list[list[int]], start: int, target: int) -> int:
    distance = [INF] * n
    settled = [False] * n
    distance[start] = 0
    for _ in range(n):
        vertex = -1
        for candidate in range(n):
            if not settled[candidate] and (vertex < 0 or distance[candidate] < distance[vertex]):
                vertex = candidate
        if vertex < 0 or distance[vertex] == INF:
            break
        settled[vertex] = True
        for neighbor, weight in enumerate(adjacency[vertex]):
            if weight > 0 and distance[neighbor] > distance[vertex] + weight:
                distance[neighbor] = distance[vertex] + weight
    return distance[target]


def _selected_edges(n: int, k: int, edges: list[tuple[int, int, int]]) -> bytes:
    adjacency = [[0] * n for _ in range(n)]
    selected = [0] * len(edges)
    order = sorted(range(len(edges)), key=lambda index: (edges[index][2], edges[index][0], edges[index][1]))
    stretch = 2 * k - 1
    for index in order:
        u, v, weight = edges[index]
        if _dijkstra(n, adjacency, u, v) > stretch * weight:
            selected[index] = 1
            adjacency[u][v] = adjacency[v][u] = weight
    return bytes(selected)


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
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    n, _, k, edges = decoded
    payload = _selected_edges(n, k, edges)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
