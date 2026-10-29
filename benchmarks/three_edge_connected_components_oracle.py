"""Brute-force edge-removal oracle for bounded three-edge components."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

MAX_VERTICES = 8
MAX_EDGES = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE_BASIS = {
    "organization": "Library Checker",
    "title": "Three-Edge-Connected Components",
    "url": "https://judge.yosupo.jp/problem/three_edge_connected_components",
    "role": "problem_taxonomy",
}


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Check all zero-, one-, and two-edge-ID removals using graph searches."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return INVALID_RESULT
    if len(values) != 2 + 2 * edge_count:
        return INVALID_RESULT
    edges: list[tuple[int, int]] = []
    for edge_id in range(edge_count):
        first, second = values[2 + 2 * edge_id:4 + 2 * edge_id]
        if not 0 <= first < vertex_count or not 0 <= second < vertex_count:
            return INVALID_RESULT
        edges.append((first, second))

    same = [[True] * vertex_count for _ in range(vertex_count)]
    removals = [()] + [(edge_id,) for edge_id in range(edge_count)]
    removals.extend(combinations(range(edge_count), 2))
    for removed in removals:
        removed_ids = set(removed)
        component = [-1] * vertex_count
        component_id = 0
        for start in range(vertex_count):
            if component[start] >= 0:
                continue
            component[start] = component_id
            queue = [start]
            for vertex in queue:
                for edge_id, (first, second) in enumerate(edges):
                    if edge_id in removed_ids:
                        continue
                    neighbor = second if first == vertex else first if second == vertex else -1
                    if neighbor >= 0 and component[neighbor] < 0:
                        component[neighbor] = component_id
                        queue.append(neighbor)
            component_id += 1

        for first in range(vertex_count):
            for second in range(first + 1, vertex_count):
                if component[first] != component[second]:
                    same[first][second] = False
                    same[second][first] = False

    labels = [-1] * vertex_count
    next_label = 0
    for first in range(vertex_count):
        if labels[first] >= 0:
            continue
        for vertex in range(first, vertex_count):
            if labels[vertex] < 0 and same[first][vertex]:
                labels[vertex] = next_label
        next_label += 1
    return sum(label * (8 ** vertex) for vertex, label in enumerate(labels))
