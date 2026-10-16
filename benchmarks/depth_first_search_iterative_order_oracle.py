"""Oracle for Graph3's iterative depth-first traversal order."""

from __future__ import annotations

import struct

MAX_VERTICES = 10
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES + 1
MAX_OUTPUT_BYTES = (MAX_VERTICES + 1) * 8


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""
    node_count, edge_count = values[:2]
    if (not 1 <= node_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 3 + 2 * edge_count):
        return -1, b""
    adjacency: list[list[int]] = [[] for _ in range(node_count + 1)]
    for offset in range(2, 2 + 2 * edge_count, 2):
        left, right = values[offset:offset + 2]
        if not 1 <= left <= node_count or not 1 <= right <= node_count:
            return -1, b""
        adjacency[left].append(right)
        adjacency[right].append(left)
    start = values[-1]
    if not 1 <= start <= node_count:
        return -1, b""

    visited = [False] * (node_count + 1)
    visited[start] = True
    stack = [start]
    order: list[int] = []
    while stack:
        vertex = stack.pop()
        order.append(vertex)
        for neighbor in adjacency[vertex]:
            if not visited[neighbor]:
                visited[neighbor] = True
                stack.append(neighbor)
    output = struct.pack("<" + "q" * (len(order) + 1), len(order), *order)
    return len(output), output
