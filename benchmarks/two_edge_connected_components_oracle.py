"""Brute-force small-graph oracle for two-edge-connected components."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_VERTICES = 6
MAX_EDGES = 10
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_VALUES = 1 + 2 * MAX_VERTICES
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_VALUES


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Find bridges by deleting each edge, then pack canonical vertex classes."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (capacity is not None and (type(capacity) is not int or capacity < 0))
        or (input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH))
        or (input_is_null and values not in (None, [], ()))
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (
        len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
        or (input_length is not None and input_length != len(values))
    ):
        return -1, b""

    vertex_count, edge_count = values[:2]
    if not (1 <= vertex_count <= MAX_VERTICES and 0 <= edge_count <= MAX_EDGES):
        return -1, b""
    if len(values) != 2 + 2 * edge_count:
        return -1, b""

    edges: list[tuple[int, int]] = []
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(vertex_count)]
    for edge_id in range(edge_count):
        left, right = values[2 + 2 * edge_id:4 + 2 * edge_id]
        if not (0 <= left < vertex_count and 0 <= right < vertex_count):
            return -1, b""
        edges.append((left, right))
        adjacency[left].append((right, edge_id))
        adjacency[right].append((left, edge_id))

    is_bridge = [False] * edge_count
    for edge_id, (left, right) in enumerate(edges):
        if left == right:
            continue
        seen = [False] * vertex_count
        seen[left] = True
        stack = [left]
        while stack:
            vertex = stack.pop()
            for neighbor, candidate_edge in adjacency[vertex]:
                if candidate_edge == edge_id or seen[neighbor]:
                    continue
                seen[neighbor] = True
                stack.append(neighbor)
        is_bridge[edge_id] = not seen[right]

    component = [-1] * vertex_count
    blocks: list[list[int]] = []
    for root in range(vertex_count):
        if component[root] >= 0:
            continue
        block_id = len(blocks)
        component[root] = block_id
        stack = [root]
        while stack:
            vertex = stack.pop()
            for neighbor, edge_id in adjacency[vertex]:
                if is_bridge[edge_id] or component[neighbor] >= 0:
                    continue
                component[neighbor] = block_id
                stack.append(neighbor)
        blocks.append([vertex for vertex in range(vertex_count) if component[vertex] == block_id])
    blocks.sort()

    packed_values = [len(blocks)]
    for block in blocks:
        packed_values.extend((len(block), *block))
    payload = b"".join(struct.pack("<Q", value) for value in packed_values)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
