"""Reference label-sequence oracle for bounded LexBFS."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 120
MAX_INPUT_LENGTH = 3 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, start = values[:3]
    if (not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES
            or not 0 <= start < n or len(values) != 3 + 2 * m):
        return None
    adjacency = [[False] * n for _ in range(n)]
    for offset in range(3, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or adjacency[u][v]:
            return None
        adjacency[u][v] = adjacency[v][u] = True
    return n, start, adjacency


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, start, adjacency = parsed
    labels: list[list[int]] = [[] for _ in range(n)]
    order: list[int] = []
    selected = [False] * n
    current = start
    for step in range(n):
        if step:
            current = max(
                (vertex for vertex in range(n) if not selected[vertex]),
                key=lambda vertex: (labels[vertex], -vertex))
        selected[current] = True
        order.append(current)
        for neighbor in range(n):
            if adjacency[current][neighbor] and not selected[neighbor]:
                labels[neighbor].insert(0, step)
    output = b"".join(struct.pack("<q", vertex) for vertex in order)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
