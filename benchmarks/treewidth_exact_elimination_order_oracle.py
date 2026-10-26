"""Primary matrix oracle for exact bounded elimination-order treewidth."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 58
MAX_OUTPUT_BYTES = 72


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
    if not 1 <= n <= MAX_N or not 0 <= edge_count <= min(28, n * (n - 1) // 2):
        return -1, b""
    if len(values) != 2 + 2 * edge_count:
        return -1, b""
    base = [[False] * n for _ in range(n)]
    for edge in range(edge_count):
        left, right = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= left < right < n or base[left][right]:
            return -1, b""
        base[left][right] = base[right][left] = True

    best_width = n + 1
    best_order: tuple[int, ...] | None = None
    for order in itertools.permutations(range(n)):
        adjacent = [row[:] for row in base]
        active = [True] * n
        width = 0
        for vertex in order:
            neighbors = [other for other in range(n)
                         if active[other] and adjacent[vertex][other]]
            width = max(width, len(neighbors))
            for index, left in enumerate(neighbors):
                for right in neighbors[index + 1:]:
                    adjacent[left][right] = adjacent[right][left] = True
            active[vertex] = False
        if width < best_width:
            best_width = width
            best_order = order
    assert best_order is not None
    payload = _pack([best_width, *best_order])
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
