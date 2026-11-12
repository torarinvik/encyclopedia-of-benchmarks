"""Independent recomputation oracle for insertion-only bridge counts."""
from __future__ import annotations

import struct
from typing import Sequence

MAX_VERTICES = 64
MAX_EDGES = 128
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_EDGES * 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _component_count(vertex_count: int, edges: Sequence[tuple[int, int]],
                     omitted_edge: int = -1) -> int:
    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    for edge_index, (left, right) in enumerate(edges):
        if edge_index == omitted_edge:
            continue
        adjacency[left].append(right)
        adjacency[right].append(left)
    seen = [False] * vertex_count
    components = 0
    for start in range(vertex_count):
        if seen[start]:
            continue
        components += 1
        seen[start] = True
        stack = [start]
        while stack:
            vertex = stack.pop()
            for neighbor in adjacency[vertex]:
                if not seen[neighbor]:
                    seen[neighbor] = True
                    stack.append(neighbor)
    return components


def _bridge_counts(vertex_count: int, inserted_edges: Sequence[tuple[int, int]]) -> list[int]:
    counts: list[int] = []
    for prefix_length in range(1, len(inserted_edges) + 1):
        prefix = inserted_edges[:prefix_length]
        component_count = _component_count(vertex_count, prefix)
        bridge_count = sum(
            _component_count(vertex_count, prefix, omitted_edge=edge_index) > component_count
            for edge_index in range(prefix_length)
        )
        counts.append(bridge_count)
    return counts


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int
                     or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""

    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return INVALID_RESULT, b""
    if len(values) != 2 + 2 * edge_count:
        return INVALID_RESULT, b""
    endpoints = values[2:]
    if any(not 0 <= endpoint < vertex_count for endpoint in endpoints):
        return INVALID_RESULT, b""

    edges = [(endpoints[index], endpoints[index + 1])
             for index in range(0, len(endpoints), 2)]
    counts = _bridge_counts(vertex_count, edges)
    payload = b"".join(struct.pack("<q", count) for count in counts)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if len(payload) > 0 and (output_is_null or capacity is not None and capacity < len(payload)):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(payload), payload
