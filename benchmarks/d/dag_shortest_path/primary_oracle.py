"""Topological-order shortest path for a bounded directed acyclic graph."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 12
MAX_EDGES = 66
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_ABS_WEIGHT = 1_000
DISTANCE_OFFSET = 100_000
INVALID_RESULT = -1
UNREACHABLE_RESULT = 0
_INFINITY = 1 << 60


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> tuple[int, int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    vertex_count, edge_count, source, target = values[:4]
    if (not 1 <= vertex_count <= MAX_VERTICES
            or not 0 <= edge_count <= MAX_EDGES
            or not 0 <= source < vertex_count
            or not 0 <= target < vertex_count
            or input_length != 4 + 3 * edge_count):
        return None
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(edge_count):
        start, end, weight = values[4 + 3 * index:7 + 3 * index]
        if (not 0 <= start < vertex_count or not 0 <= end < vertex_count
                or start == end or not -MAX_ABS_WEIGHT <= weight <= MAX_ABS_WEIGHT
                or (start, end) in seen):
            return None
        seen.add((start, end))
        edges.append((start, end, weight))
    return vertex_count, source, edges


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return an offset distance, zero if unreachable, or -1 for invalid input."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertex_count, source, edges = parsed
    if input_is_null or values is None:
        return INVALID_RESULT
    target = values[3]
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(vertex_count)]
    indegree = [0] * vertex_count
    for start, end, weight in edges:
        adjacency[start].append((end, weight))
        indegree[end] += 1
    ready = [vertex for vertex in range(vertex_count) if indegree[vertex] == 0]
    order: list[int] = []
    cursor = 0
    while cursor < len(ready):
        vertex = ready[cursor]
        cursor += 1
        order.append(vertex)
        for neighbor, _ in adjacency[vertex]:
            indegree[neighbor] -= 1
            if indegree[neighbor] == 0:
                ready.append(neighbor)
    if len(order) != vertex_count:
        return INVALID_RESULT

    distance = [_INFINITY] * vertex_count
    distance[source] = 0
    for vertex in order:
        if distance[vertex] == _INFINITY:
            continue
        for neighbor, weight in adjacency[vertex]:
            candidate = distance[vertex] + weight
            if candidate < distance[neighbor]:
                distance[neighbor] = candidate
    return UNREACHABLE_RESULT if distance[target] == _INFINITY else DISTANCE_OFFSET + distance[target]
