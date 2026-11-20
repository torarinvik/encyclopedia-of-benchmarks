"""Exhaustive subset oracle for the maximum rainbow-forest cardinality."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 10
MAX_EDGES = 20
MAX_COLORS = 8
MAX_PARSEABLE_INPUT_LENGTH = 3 + MAX_COLORS + 3 * MAX_EDGES + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m, c = values[:3]
    if (n < 1 or n > MAX_VERTICES or m < 0 or m > MAX_EDGES
            or c < 1 or c > MAX_COLORS or len(values) != 3 + c + 3 * m):
        return None
    caps = values[3:3 + c]
    if any(cap < 0 or cap > MAX_EDGES for cap in caps):
        return None
    edges = []
    pos = 3 + c
    for i in range(m):
        u, v, color = values[pos + 3 * i:pos + 3 * i + 3]
        if u < 0 or u >= n or v < 0 or v >= n or color < 0 or color >= c:
            return None
        edges.append((u, v, color))
    return n, m, c, caps, edges


def _valid_subset(vertices: int, color_count: int, capacities: Sequence[int],
                  edges: Sequence[tuple[int, int, int]], mask: int) -> bool:
    parent = list(range(vertices))
    color_totals = [0] * color_count
    for edge_id, (u, v, color) in enumerate(edges):
        if not (mask >> edge_id) & 1:
            continue
        color_totals[color] += 1
        if color_totals[color] > capacities[color]:
            return False
        a, b = u, v
        while parent[a] != a:
            a = parent[a]
        while parent[b] != b:
            b = parent[b]
        if a == b:
            return False
        parent[b] = a
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertices, edge_count, color_count, capacities, edges = parsed
    best = 0
    for mask in range(1 << edge_count):
        count = mask.bit_count()
        if count > best and _valid_subset(vertices, color_count, capacities, edges, mask):
            best = count
    return best
