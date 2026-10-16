"""Reference model for a bounded directed Eulerian path."""

from __future__ import annotations

import struct

INVALID_RESULT = -1
MAX_VERTICES = 32
MAX_EDGES = 256
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (MAX_EDGES + 1)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return path bytes, zero bytes for no path, or -1 for malformed input."""
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    vertex_count, edge_count = values[:2]
    if (not 0 <= vertex_count <= MAX_VERTICES
            or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count):
        return INVALID_RESULT, b""

    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    in_degree = [0] * vertex_count
    out_degree = [0] * vertex_count
    for offset in range(2, len(values), 2):
        source, destination = values[offset:offset + 2]
        if not 0 <= source < vertex_count or not 0 <= destination < vertex_count:
            return INVALID_RESULT, b""
        adjacency[source].append(destination)
        out_degree[source] += 1
        in_degree[destination] += 1

    if edge_count == 0:
        return 0, b""

    start = None
    start_count = 0
    end_count = 0
    for vertex in range(vertex_count):
        difference = out_degree[vertex] - in_degree[vertex]
        if difference == 1:
            start = vertex
            start_count += 1
        elif difference == -1:
            end_count += 1
        elif difference != 0:
            return 0, b""
    if not ((start_count == 0 and end_count == 0)
            or (start_count == 1 and end_count == 1)):
        return 0, b""
    if start is None:
        start = next((vertex for vertex, degree in enumerate(out_degree) if degree), None)
    if start is None:
        return 0, b""

    remaining = out_degree.copy()
    stack = [start]
    reverse_path: list[int] = []
    while stack:
        current = stack[-1]
        if remaining[current] > 0:
            remaining[current] -= 1
            stack.append(adjacency[current][remaining[current]])
        else:
            reverse_path.append(stack.pop())
    if len(reverse_path) != edge_count + 1:
        return 0, b""

    path = reversed(reverse_path)
    output = b"".join(struct.pack("<q", vertex) for vertex in path)
    return len(output), output
