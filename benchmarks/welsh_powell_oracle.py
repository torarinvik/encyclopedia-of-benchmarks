"""Independent oracle for bounded Welsh-Powell greedy graph coloring."""

from __future__ import annotations

import struct

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_VERTICES = 32
MAX_EDGE_PAIRS = 512
MAX_VALIDATION_LENGTH = 2 + 2 * MAX_EDGE_PAIRS + 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the source-ordered color vector as little-endian signed i64 words."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_VALIDATION_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""

    vertex_count, edge_count = values[:2]
    if not 0 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGE_PAIRS:
        return -1, b""
    if len(values) != 2 + 2 * edge_count:
        return -1, b""

    adjacency = [set() for _ in range(vertex_count)]
    for edge in range(edge_count):
        left, right = values[2 + 2 * edge : 4 + 2 * edge]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count or left == right:
            return -1, b""
        adjacency[left].add(right)
        adjacency[right].add(left)

    # Python's sort is stable, so equal-degree vertices keep ascending index order.
    order = sorted(range(vertex_count), key=lambda vertex: -len(adjacency[vertex]))
    colors = [-1] * vertex_count
    colored: set[int] = set()

    for vertex in order:
        if colors[vertex] != -1:
            continue

        used_colors = {colors[neighbor] for neighbor in adjacency[vertex] if colors[neighbor] != -1}
        color = 0
        while color in used_colors:
            color += 1
        colors[vertex] = color
        colored.add(vertex)

        # Match the source: any already-colored neighbor blocks this bulk assignment,
        # even when that neighbor has a different color.
        for other in order:
            if colors[other] == -1 and not adjacency[other].intersection(colored):
                colors[other] = color
                colored.add(other)

    output = b"".join(struct.pack("<q", color) for color in colors)
    return len(output), output
