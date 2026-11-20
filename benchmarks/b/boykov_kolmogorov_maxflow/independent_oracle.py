"""Independent exhaustive minimum-cut reference for bounded networks."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 2
MAX_VERTICES = 8
MAX_EDGES = 16
MAX_CAPACITY = 15
MAX_INPUT_LENGTH = 53


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return -1
    vertex_count, edge_count, source, sink = values[:4]
    if (not MIN_VERTICES <= vertex_count <= MAX_VERTICES
            or not 0 <= edge_count <= MAX_EDGES
            or not 0 <= source < vertex_count or not 0 <= sink < vertex_count
            or source == sink or len(values) != 4 + 3 * edge_count):
        return -1
    edges: list[tuple[int, int, int]] = []
    for offset in range(4, len(values), 3):
        left, right, capacity = values[offset:offset + 3]
        if (not 0 <= left < vertex_count or not 0 <= right < vertex_count
                or left == right or not 0 <= capacity <= MAX_CAPACITY):
            return -1
        edges.append((left, right, capacity))

    best = MAX_EDGES * MAX_CAPACITY + 1
    for side in range(1 << vertex_count):
        if not side & (1 << source) or side & (1 << sink):
            continue
        cut_capacity = sum(
            capacity for left, right, capacity in edges
            if side & (1 << left) and not side & (1 << right)
        )
        best = min(best, cut_capacity)
    return best
