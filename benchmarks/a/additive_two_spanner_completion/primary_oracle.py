"""Bounded deterministic form of 2-spanner completion."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_M)
INF = MAX_N + 1


def _parse(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for edge_id in range(m):
        u, v = values[2 + 2 * edge_id:4 + 2 * edge_id]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def _adjacency(n: int, edges: list[tuple[int, int]], selected: list[bool] | None = None):
    graph = [[False] * n for _ in range(n)]
    for edge_id, (u, v) in enumerate(edges):
        if selected is None or selected[edge_id]:
            graph[u][v] = graph[v][u] = True
    return graph


def _distances(graph: list[list[bool]], start: int) -> list[int]:
    distance = [INF] * len(graph)
    distance[start] = 0
    queue = [start]
    for vertex in queue:
        for neighbor, adjacent in enumerate(graph[vertex]):
            if adjacent and distance[neighbor] == INF:
                distance[neighbor] = distance[vertex] + 1
                queue.append(neighbor)
    return distance


def _all_distances(graph: list[list[bool]]) -> list[list[int]]:
    return [_distances(graph, start) for start in range(len(graph))]


def _construct(n: int, edges: list[tuple[int, int]]) -> list[bool]:
    original = _adjacency(n, edges)
    graph_distance = _all_distances(original)
    selected = [False] * len(edges)
    while True:
        current = _all_distances(_adjacency(n, edges, selected))
        violating_pair = None
        for u in range(n):
            for v in range(u + 1, n):
                if (graph_distance[u][v] < INF
                        and current[u][v] > graph_distance[u][v] + 2):
                    violating_pair = (u, v)
                    break
            if violating_pair is not None:
                break
        if violating_pair is None:
            return selected

        source, target = violating_pair
        remaining = graph_distance[target]
        vertex = source
        while vertex != target:
            next_vertex = -1
            for neighbor in range(n):
                if original[vertex][neighbor] and remaining[neighbor] == remaining[vertex] - 1:
                    next_vertex = neighbor
                    break
            if next_vertex < 0:
                return selected
            edge_id = next(index for index, edge in enumerate(edges)
                           if edge == (min(vertex, next_vertex), max(vertex, next_vertex)))
            selected[edge_id] = True
            vertex = next_vertex


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    selected = _construct(n, edges)
    chosen = [(u, v) for edge_id, (u, v) in enumerate(edges) if selected[edge_id]]
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(endpoint for edge in chosen for endpoint in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
