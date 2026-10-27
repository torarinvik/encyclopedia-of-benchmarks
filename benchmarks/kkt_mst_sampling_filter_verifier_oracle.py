"""Prim/BFS verifier for the KKT sampled minimum-spanning-forest filter."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_N = 12
MAX_M = 24
MAX_INPUT = 98


def _valid(values: Sequence[int]) -> tuple[int, list[tuple[int, int, int, int]]] | None:
    if len(values) < 6 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m = values[0], values[1]
    if not 2 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 2 + 4*m:
        return None
    edges = [tuple(values[2 + 4*i:6 + 4*i]) for i in range(m)]
    pairs: set[tuple[int, int]] = set()
    weights: set[int] = set()
    for u, v, weight, sample in edges:
        if not 0 <= u < v < n or not 1 <= weight <= 1024 or sample not in (0, 1):
            return None
        if (u, v) in pairs or weight in weights:
            return None
        pairs.add((u, v))
        weights.add(weight)
    return n, edges


def _prim_filter(n: int, edges: list[tuple[int, int, int, int]]) -> bytes:
    tree = [[0] * n for _ in range(n)]
    chosen: set[int] = set()
    visited = [False] * n
    for root in range(n):
        if visited[root]:
            continue
        visited[root] = True
        while True:
            best: tuple[int, int, int] | None = None
            for index, (u, v, weight, sample) in enumerate(edges):
                if sample and visited[u] != visited[v]:
                    candidate = (weight, index, v if visited[u] else u)
                    if best is None or candidate < best:
                        best = candidate
            if best is None:
                break
            weight, index, new_vertex = best
            u, v, _, _ = edges[index]
            tree[u][v] = tree[v][u] = weight
            chosen.add(index)
            visited[new_vertex] = True

    result = bytearray()
    for index, (source, target, edge_weight, _) in enumerate(edges):
        if index in chosen:
            result.append(1)
            continue
        path_max = [-1] * n
        path_max[source] = 0
        todo = deque([source])
        while todo and path_max[target] < 0:
            vertex = todo.popleft()
            for neighbor, weight in enumerate(tree[vertex]):
                if weight and path_max[neighbor] < 0:
                    path_max[neighbor] = max(path_max[vertex], weight)
                    todo.append(neighbor)
        result.append(1 if path_max[target] < 0 or edge_weight < path_max[target] else 0)
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
    parsed = _valid(values)
    if parsed is None:
        return -1, b""
    payload = _prim_filter(*parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
