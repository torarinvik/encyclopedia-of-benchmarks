"""Kruskal-based exact oracle for the KKT sampled-MSF filter stage."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_N = 12
MAX_M = 24
MAX_INPUT = 98
MAX_OUTPUT_BYTES = 24


def _parse(values: Sequence[int]) -> tuple[int, list[tuple[int, int, int, int]]] | None:
    if len(values) < 6 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m = values[:2]
    if not 2 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 2 + 4*m:
        return None
    edges: list[tuple[int, int, int, int]] = []
    seen_pairs: set[tuple[int, int]] = set()
    seen_weights: set[int] = set()
    for index in range(m):
        u, v, weight, sampled = values[2 + 4*index:6 + 4*index]
        if not 0 <= u < v < n or not 1 <= weight <= 1024 or sampled not in (0, 1):
            return None
        if (u, v) in seen_pairs or weight in seen_weights:
            return None
        seen_pairs.add((u, v))
        seen_weights.add(weight)
        edges.append((u, v, weight, sampled))
    return n, edges


def _filter(n: int, edges: list[tuple[int, int, int, int]]) -> bytes:
    parent = list(range(n))

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    forest = [[0] * n for _ in range(n)]
    in_forest = [False] * len(edges)
    for index in sorted((i for i, edge in enumerate(edges) if edge[3]), key=lambda i: edges[i][2]):
        u, v, weight, _ = edges[index]
        left, right = find(u), find(v)
        if left != right:
            parent[right] = left
            in_forest[index] = True
            forest[u][v] = forest[v][u] = weight

    result = bytearray()
    for index, (u, v, weight, _) in enumerate(edges):
        if in_forest[index]:
            result.append(1)
            continue
        queue = deque([u])
        maximum = [-1] * n
        maximum[u] = 0
        while queue and maximum[v] < 0:
            current = queue.popleft()
            for neighbor, path_edge_weight in enumerate(forest[current]):
                if path_edge_weight and maximum[neighbor] < 0:
                    maximum[neighbor] = max(maximum[current], path_edge_weight)
                    queue.append(neighbor)
        result.append(1 if maximum[v] < 0 or weight < maximum[v] else 0)
    return bytes(result)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _filter(*parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
