"""Subset-enumeration verifier for exact induced edge density."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

MIN_VERTICES = 2
MAX_VERTICES = 8
MAX_EDGES = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return INVALID_RESULT
    if len(values) != 2 + 2 * m:
        return INVALID_RESULT
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for at in range(2, len(values), 2):
        u, v = values[at], values[at + 1]
        if not 0 <= u < v < n or (u, v) in seen:
            return INVALID_RESULT
        seen.add((u, v))
        edges.append((u, v))

    best_edges = 0
    best_vertices = 1
    for mask in range(1, 1 << n):
        vertex_count = mask.bit_count()
        edge_count = sum((mask >> u) & 1 and (mask >> v) & 1 for u, v in edges)
        if edge_count * best_vertices > best_edges * vertex_count:
            best_edges, best_vertices = edge_count, vertex_count
    divisor = gcd(best_edges, best_vertices)
    numerator = best_edges // divisor
    denominator = best_vertices // divisor
    return numerator * (n + 1) + denominator
