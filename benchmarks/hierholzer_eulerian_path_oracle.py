"""Oracle for the bounded directed Hierholzer Eulerian-path benchmark."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 16
MAX_EDGES = 48
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (MAX_EDGES + 2)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _find_path(adjacency: list[list[int]], in_degree: list[int],
               out_degree: list[int], edge_count: int) -> list[int]:
    vertex_count = len(adjacency)
    if vertex_count == 0:
        return []
    if edge_count == 0:
        return [0]

    start = -1
    start_count = 0
    end_count = 0
    for vertex in range(vertex_count):
        difference = out_degree[vertex] - in_degree[vertex]
        if difference == 1:
            start = vertex
            start_count += 1
        elif difference == -1:
            end_count += 1
        elif abs(difference) > 1:
            return []
    if not ((start_count == 1 and end_count == 1)
            or (start_count == 0 and end_count == 0)):
        return []
    if start < 0:
        start = next(vertex for vertex, degree in enumerate(out_degree) if degree > 0)

    visited = [False] * vertex_count
    visited[start] = True
    pending = [start]
    while pending:
        current = pending.pop()
        for destination in adjacency[current]:
            if not visited[destination]:
                visited[destination] = True
                pending.append(destination)
        for source in range(vertex_count):
            if visited[source]:
                continue
            for destination in adjacency[source]:
                if destination == current:
                    visited[source] = True
                    pending.append(source)
                    break
    if any((in_degree[vertex] + out_degree[vertex] > 0 and not visited[vertex])
           for vertex in range(vertex_count)):
        return []

    next_position = [0] * vertex_count
    stack = [start]
    reverse_path: list[int] = []
    while stack:
        current = stack[-1]
        if next_position[current] < len(adjacency[current]):
            destination = adjacency[current][next_position[current]]
            next_position[current] += 1
            stack.append(destination)
        else:
            reverse_path.append(stack.pop())

    path = reverse_path[::-1]
    if len(path) != edge_count + 1:
        return []
    # The source's preferred circuit start is the first nonempty adjacency row.
    # start was selected by that same ascending scan, so its rotation is a no-op.
    return path


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""

    vertex_count, edge_count = values[:2]
    if (not 0 <= vertex_count <= MAX_VERTICES
            or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count):
        return -1, b""

    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    in_degree = [0] * vertex_count
    out_degree = [0] * vertex_count
    for edge in range(edge_count):
        source, destination = values[2 + 2 * edge:4 + 2 * edge]
        if not (0 <= source < vertex_count and 0 <= destination < vertex_count):
            return -1, b""
        adjacency[source].append(destination)
        out_degree[source] += 1
        in_degree[destination] += 1

    path = _find_path(adjacency, in_degree, out_degree, edge_count)
    encoded = struct.pack("<q", len(path)) + b"".join(
        struct.pack("<q", vertex) for vertex in path
    )
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
