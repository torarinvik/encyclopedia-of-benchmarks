"""Independent exact oracle for bounded undirected graph coloring counts."""

from __future__ import annotations

import struct

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_VERTICES = 8
MAX_COLORS = 4
MAX_INPUT_LENGTH = MAX_VERTICES + 2
MAX_VALIDATION_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the little-endian i64 count of all proper labeled colorings."""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_VALIDATION_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    vertex_count, color_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 1 <= color_count <= MAX_COLORS:
        return -1, b""
    if len(values) != vertex_count + 2:
        return -1, b""
    masks = values[2:]
    limit = 1 << vertex_count
    if any(mask < 0 or mask >= limit for mask in masks):
        return -1, b""
    if any(mask & (1 << vertex) for vertex, mask in enumerate(masks)):
        return -1, b""
    for vertex in range(vertex_count):
        for neighbor in range(vertex_count):
            if ((masks[vertex] >> neighbor) & 1) != ((masks[neighbor] >> vertex) & 1):
                return -1, b""

    colors = [-1] * vertex_count

    def count_from(vertex: int) -> int:
        if vertex == vertex_count:
            return 1
        count = 0
        for color in range(color_count):
            if all(not ((masks[vertex] >> prior) & 1) or colors[prior] != color
                   for prior in range(vertex)):
                colors[vertex] = color
                count += count_from(vertex + 1)
        return count

    return MAX_OUTPUT_BYTES, struct.pack("<q", count_from(0))
