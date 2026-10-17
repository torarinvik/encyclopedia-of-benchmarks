"""Oracle for the bounded, unique-order Kahn topological-sort contract."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 32
MAX_EDGES = 128
MAX_INPUT_LENGTH = 1 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 4 * MAX_VERTICES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or
            not 1 <= len(values) <= MAX_INPUT_LENGTH or
            any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                for value in values)):
        return -1, b""

    edge_count = values[0]
    if not 0 <= edge_count <= MAX_EDGES or len(values) != 1 + 2 * edge_count:
        return -1, b""

    vertices: list[int] = []
    vertex_index: dict[int, int] = {}
    edges: list[tuple[int, int]] = []
    for offset in range(edge_count):
        source, destination = values[1 + 2 * offset:3 + 2 * offset]
        if not I32_MIN <= source <= I32_MAX or not I32_MIN <= destination <= I32_MAX:
            return -1, b""
        for vertex in (source, destination):
            if vertex not in vertex_index:
                if len(vertices) >= MAX_VERTICES:
                    return -1, b""
                vertex_index[vertex] = len(vertices)
                vertices.append(vertex)
        edges.append((source, destination))

    adjacency: list[list[int]] = [[] for _ in vertices]
    indegree = [0] * len(vertices)
    for source, destination in edges:
        source_index = vertex_index[source]
        destination_index = vertex_index[destination]
        adjacency[source_index].append(destination_index)
        indegree[destination_index] += 1

    queue = [index for index, degree in enumerate(indegree) if degree == 0]
    order: list[int] = []
    head = 0
    while head < len(queue):
        if len(queue) - head != 1:
            return -1, b""
        current = queue[head]
        head += 1
        order.append(vertices[current])
        for adjacent in adjacency[current]:
            indegree[adjacent] -= 1
            if indegree[adjacent] == 0:
                queue.append(adjacent)

    if len(order) != len(vertices):
        return -1, b""
    encoded = b"".join(struct.pack("<i", value) for value in order)
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
