"""Equal-weight Kruskal groups with edge-ID-aware quotient bridges."""
from __future__ import annotations

from typing import Sequence

MAX_VERTICES = 12
MAX_EDGES = 24
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_EDGES
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if len(values) != 2 + 3 * edge_count:
        return None
    edges: list[tuple[int, int, int]] = []
    pairs: set[tuple[int, int]] = set()
    for index in range(edge_count):
        left, right, weight = values[2 + 3 * index:5 + 3 * index]
        if not 0 <= left < right < vertex_count or not 0 <= weight <= 20:
            return None
        if (left, right) in pairs:
            return None
        pairs.add((left, right))
        edges.append((left, right, weight))
    return vertex_count, edges


def _find(parent: list[int], vertex: int) -> int:
    while parent[vertex] != vertex:
        parent[vertex] = parent[parent[vertex]]
        vertex = parent[vertex]
    return vertex


def _union(parent: list[int], left: int, right: int) -> None:
    left_root = _find(parent, left)
    right_root = _find(parent, right)
    if left_root != right_root:
        parent[right_root] = left_root


def _group_bridges(vertex_count: int, candidates: list[tuple[int, int, int]]) -> set[int]:
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(vertex_count)]
    for left, right, edge_id in candidates:
        adjacency[left].append((right, edge_id))
        adjacency[right].append((left, edge_id))

    discovery = [-1] * vertex_count
    low = [0] * vertex_count
    bridges: set[int] = set()
    clock = 0

    def visit(vertex: int, parent_edge: int) -> None:
        nonlocal clock
        discovery[vertex] = low[vertex] = clock
        clock += 1
        for neighbor, edge_id in adjacency[vertex]:
            if edge_id == parent_edge:
                continue
            if discovery[neighbor] == -1:
                visit(neighbor, edge_id)
                low[vertex] = min(low[vertex], low[neighbor])
                if low[neighbor] > discovery[vertex]:
                    bridges.add(edge_id)
            else:
                low[vertex] = min(low[vertex], discovery[neighbor])

    for vertex in range(vertex_count):
        if discovery[vertex] == -1 and adjacency[vertex]:
            visit(vertex, -1)
    return bridges


def _classify(vertex_count: int, edges: list[tuple[int, int, int]]) -> bytes | None:
    parent = list(range(vertex_count))
    ordered = sorted(range(len(edges)), key=lambda edge_id: (edges[edge_id][2], edge_id))
    classes = bytearray(len(edges))
    start = 0
    while start < len(ordered):
        stop = start + 1
        weight = edges[ordered[start]][2]
        while stop < len(ordered) and edges[ordered[stop]][2] == weight:
            stop += 1
        candidates: list[tuple[int, int, int]] = []
        for position in range(start, stop):
            edge_id = ordered[position]
            left, right, _ = edges[edge_id]
            left_root = _find(parent, left)
            right_root = _find(parent, right)
            if left_root != right_root:
                candidates.append((left_root, right_root, edge_id))
        bridge_ids = _group_bridges(vertex_count, candidates)
        for _, _, edge_id in candidates:
            classes[edge_id] = 2 if edge_id in bridge_ids else 1
        for position in range(start, stop):
            left, right, _ = edges[ordered[position]]
            _union(parent, left, right)
        start = stop
    if any(_find(parent, vertex) != _find(parent, 0) for vertex in range(vertex_count)):
        return None
    return bytes(classes)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    vertex_count, edges = parsed
    payload = _classify(vertex_count, edges)
    if payload is None:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if len(payload) and (
        output_is_null
        or output_capacity is not None and output_capacity < len(payload)
    ):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(payload), payload
