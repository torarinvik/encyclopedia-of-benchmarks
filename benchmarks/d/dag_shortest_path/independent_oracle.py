"""Independent finite-path reference for a bounded DAG shortest-path query."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    DISTANCE_OFFSET,
    INVALID_RESULT,
    MAX_ABS_WEIGHT,
    MAX_EDGES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VERTICES,
    UNREACHABLE_RESULT,
)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return INVALID_RESULT
    vertex_count, edge_count, source, target = values[:4]
    if (not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or not 0 <= source < vertex_count or not 0 <= target < vertex_count
            or input_length != 4 + 3 * edge_count):
        return INVALID_RESULT
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(vertex_count)]
    reach = [[False] * vertex_count for _ in range(vertex_count)]
    seen: set[tuple[int, int]] = set()
    for index in range(edge_count):
        start, end, weight = values[4 + 3 * index:7 + 3 * index]
        if (not 0 <= start < vertex_count or not 0 <= end < vertex_count
                or start == end or not -MAX_ABS_WEIGHT <= weight <= MAX_ABS_WEIGHT
                or (start, end) in seen):
            return INVALID_RESULT
        seen.add((start, end))
        adjacency[start].append((end, weight))
        reach[start][end] = True

    # Transitive closure detects cycles independently of the primary Kahn pass.
    for pivot in range(vertex_count):
        for start in range(vertex_count):
            if reach[start][pivot]:
                for end in range(vertex_count):
                    reach[start][end] = reach[start][end] or reach[pivot][end]
    if any(reach[vertex][vertex] for vertex in range(vertex_count)):
        return INVALID_RESULT

    best: int | None = None
    visited = [False] * vertex_count

    def enumerate_paths(vertex: int, total: int) -> None:
        nonlocal best
        if vertex == target:
            if best is None or total < best:
                best = total
            return
        visited[vertex] = True
        for neighbor, weight in adjacency[vertex]:
            if not visited[neighbor]:
                enumerate_paths(neighbor, total + weight)
        visited[vertex] = False

    enumerate_paths(source, 0)
    return UNREACHABLE_RESULT if best is None else DISTANCE_OFFSET + best


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
