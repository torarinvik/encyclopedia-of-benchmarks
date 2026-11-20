"""Direct per-query scan of every segment for the nearest vertical-ray hit."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import _decode
except ImportError:  # Direct invocation from the package directory.
    from primary_oracle import _decode


def _direct_height(points: list[tuple[int, int]], edge: tuple[int, int, int],
                   x: int) -> tuple[int, int]:
    first, second = points[edge[0]], points[edge[1]]
    left, right = (first, second) if first[0] < second[0] else (second, first)
    width = right[0] - left[0]
    numerator = left[1] * width + (right[1] - left[1]) * (x - left[0])
    return numerator, width


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    points, edges, queries, face_count = decoded
    result = 0
    for query_number, (x, y) in enumerate(queries, 1):
        best_edge = -1
        best_numerator = 0
        best_denominator = 1
        on_edge = -1
        for edge_id, edge in enumerate(edges):
            first, second = points[edge[0]], points[edge[1]]
            left, right = (first, second) if first[0] < second[0] else (second, first)
            if not left[0] < x < right[0]:
                continue
            numerator, denominator = _direct_height(points, edge, x)
            query_scaled = y * denominator
            if numerator == query_scaled:
                on_edge = edge_id
                break
            if numerator < query_scaled and (
                    best_edge < 0 or numerator * best_denominator > best_numerator * denominator):
                best_edge = edge_id
                best_numerator = numerator
                best_denominator = denominator
        if on_edge >= 0:
            answer = face_count + on_edge + 1
        elif best_edge < 0 or edges[best_edge][2] < 0:
            answer = 0
        else:
            answer = edges[best_edge][2] + 1
        result += query_number * answer
    return result
