"""Bounded deterministic oracle for vertex-biconnected components."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_VERTICES = 6
MAX_EDGES = 10
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_BLOCKS = MAX_VERTICES + MAX_EDGES
MAX_OUTPUT_VALUES = 1 + MAX_BLOCKS * (MAX_VERTICES + 1)
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_VALUES


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return canonical sorted block vertex sets packed as little-endian u64s."""
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
        if not (0 <= left < vertex_count and 0 <= right < vertex_count) or left == right:
            return -1, b""
        edges.append((left, right))
        adjacency[left].append((right, edge_id))
        adjacency[right].append((left, edge_id))

    discovery = [-1] * vertex_count
    low = [0] * vertex_count
    edge_stack: list[int] = []
    blocks: list[list[int]] = []
    clock = 0

    def visit(vertex: int, parent_edge: int) -> None:
        nonlocal clock
        discovery[vertex] = low[vertex] = clock
        clock += 1
        for neighbor, edge_id in adjacency[vertex]:
            if edge_id == parent_edge:
                continue
            if discovery[neighbor] < 0:
                edge_stack.append(edge_id)
                visit(neighbor, edge_id)
                low[vertex] = min(low[vertex], low[neighbor])
                if low[neighbor] >= discovery[vertex]:
                    members: set[int] = set()
                    while edge_stack:
                        popped = edge_stack.pop()
                        left, right = edges[popped]
                        members.add(left)
                        members.add(right)
                        if popped == edge_id:
                            break
                    blocks.append(sorted(members))
            elif discovery[neighbor] < discovery[vertex]:
                edge_stack.append(edge_id)
                low[vertex] = min(low[vertex], discovery[neighbor])

    for root in range(vertex_count):
        if discovery[root] >= 0:
            continue
        visit(root, -1)
        if not adjacency[root]:
            blocks.append([root])
    blocks.sort()

    packed_values = [len(blocks)]
    for block in blocks:
        packed_values.extend((len(block), *block))
    payload = b"".join(struct.pack("<Q", value) for value in packed_values)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
