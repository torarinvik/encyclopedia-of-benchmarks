"""Independent subset oracle for the bounded GBBS k-core profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _graph(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return None
    node_count, edge_count = values[:2]
    if (not 1 <= node_count <= MAX_NODES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count):
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        left, right = values[offset : offset + 2]
        if not 0 <= left < right < node_count or (left, right) in seen:
            return None
        seen.add((left, right))
        edges.append((left, right))
    return node_count, edges


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Compute each core number by exhaustive induced-subset search."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)):
        return INVALID_RESULT, b""
    parsed = _graph(values)
    if parsed is None:
        return INVALID_RESULT, b""
    node_count, edges = parsed
    adjacency = [[False] * node_count for _ in range(node_count)]
    for left, right in edges:
        adjacency[left][right] = adjacency[right][left] = True

    neighbor_masks = [
        sum((1 << neighbor) for neighbor in range(node_count) if adjacency[vertex][neighbor])
        for vertex in range(node_count)
    ]
    core = [0] * node_count
    for subset in range(1, 1 << node_count):
        minimum_degree = node_count
        members = subset
        while members:
            bit = members & -members
            vertex = bit.bit_length() - 1
            minimum_degree = min(minimum_degree, (neighbor_masks[vertex] & subset).bit_count())
            members ^= bit
        members = subset
        while members:
            bit = members & -members
            vertex = bit.bit_length() - 1
            core[vertex] = max(core[vertex], minimum_degree)
            members ^= bit

    output = b"".join(struct.pack("<q", value) for value in core)
    if output_is_null or output_capacity is not None and output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    return expected_output(values)
