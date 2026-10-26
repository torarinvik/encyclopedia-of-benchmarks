"""Primary oracle for the chapter's deterministic bounded min-degree profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 242
MAX_OUTPUT = 2064


def _pack(words: list[int]) -> bytes:
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))
            or len(values) < 2 or len(values) > MAX_INPUT
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, edge_count = values[:2]
    if not 1 <= n <= 16 or not 0 <= edge_count <= 120:
        return -1, b""
    if edge_count > n * (n - 1) // 2 or len(values) != 2 + 2 * edge_count:
        return -1, b""
    adjacent = [[False] * n for _ in range(n)]
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left < right < n or adjacent[left][right]:
            return -1, b""
        adjacent[left][right] = adjacent[right][left] = True

    active = [True] * n
    order: list[int] = []
    fill_edges: list[tuple[int, int]] = []
    width = 0
    for _ in range(n):
        degrees = [sum(active[neighbor] and adjacent[vertex][neighbor]
                       for neighbor in range(n)) if active[vertex] else n + 1
                   for vertex in range(n)]
        chosen = min(range(n), key=lambda vertex: (degrees[vertex], vertex))
        degree = degrees[chosen]
        width = max(width, degree)
        order.append(chosen)
        neighbors = [vertex for vertex in range(n)
                     if active[vertex] and adjacent[chosen][vertex]]
        for i, left in enumerate(neighbors):
            for right in neighbors[i + 1:]:
                if not adjacent[left][right]:
                    adjacent[left][right] = adjacent[right][left] = True
                    fill_edges.append((left, right))
        active[chosen] = False

    words = [width, *order, len(fill_edges)]
    for left, right in fill_edges:
        words.extend((left, right))
    payload = _pack(words)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
