"""Independent Floyd-Warshall reference for 2-spanner completion."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_PARSEABLE_INPUT_LENGTH = 59
MAX_OUTPUT_BYTES = 456
INF = 99


def _read(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for record in range(m):
        u, v = values[2 + 2 * record], values[3 + 2 * record]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def _floyd(n: int, edges: list[tuple[int, int]], selected: list[bool] | None = None):
    distance = [[0 if u == v else INF for v in range(n)] for u in range(n)]
    for edge_id, (u, v) in enumerate(edges):
        if selected is None or selected[edge_id]:
            distance[u][v] = distance[v][u] = 1
    for via in range(n):
        for left in range(n):
            for right in range(n):
                candidate = distance[left][via] + distance[via][right]
                if candidate < distance[left][right]:
                    distance[left][right] = candidate
    return distance


def _construct(n: int, edges: list[tuple[int, int]]) -> list[bool]:
    graph_distance = _floyd(n, edges)
    selected = [False] * len(edges)
    while True:
        current = _floyd(n, edges, selected)
        pair = next(((u, v) for u in range(n) for v in range(u + 1, n)
                     if graph_distance[u][v] < INF
                     and current[u][v] > graph_distance[u][v] + 2), None)
        if pair is None:
            return selected
        source, target = pair
        vertex = source
        while vertex != target:
            next_vertex = next((neighbor for neighbor in range(n)
                                if (min(vertex, neighbor), max(vertex, neighbor)) in edges
                                and graph_distance[neighbor][target]
                                == graph_distance[vertex][target] - 1), None)
            if next_vertex is None:
                return selected
            wanted = (min(vertex, next_vertex), max(vertex, next_vertex))
            selected[edges.index(wanted)] = True
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
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    selected = _construct(n, edges)
    chosen = [edge for edge_id, edge in enumerate(edges) if selected[edge_id]]
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(endpoint for edge in chosen for endpoint in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
