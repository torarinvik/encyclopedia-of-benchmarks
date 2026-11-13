"""Independent exhaustive triangulation enumerator for min-max edge length."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MIN_VERTICES = 3
MAX_VERTICES = 12
COORDINATE_LIMIT = 1000
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _valid_polygon(values: Sequence[int] | None, input_is_null: bool,
                   input_length: int | None) -> tuple[tuple[int, int], ...] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 1
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH or actual_length != len(values)):
        return None
    if any(type(item) is not int or not -(1 << 63) <= item < (1 << 63) for item in values):
        return None
    vertex_count = values[0]
    if not MIN_VERTICES <= vertex_count <= MAX_VERTICES or actual_length != 1 + 2 * vertex_count:
        return None
    points = tuple((values[1 + 2 * index], values[2 + 2 * index]) for index in range(vertex_count))
    if any(abs(x) > COORDINATE_LIMIT or abs(y) > COORDINATE_LIMIT for x, y in points):
        return None

    signed_area = 0
    for index in range(vertex_count):
        x0, y0 = points[index]
        x1, y1 = points[(index + 1) % vertex_count]
        signed_area += x0 * y1 - y0 * x1
    if signed_area == 0:
        return None
    orientation = 1 if signed_area > 0 else -1
    for first in range(vertex_count):
        x0, y0 = points[first]
        x1, y1 = points[(first + 1) % vertex_count]
        for other in range(vertex_count):
            if other == first or other == (first + 1) % vertex_count:
                continue
            x, y = points[other]
            if orientation * ((x1 - x0) * (y - y0) - (y1 - y0) * (x - x0)) <= 0:
                return None
    return points


def _enumerate_score(points: tuple[tuple[int, int], ...]) -> int:
    @lru_cache(maxsize=None)
    def all_edge_sets(left: int, right: int) -> tuple[frozenset[tuple[int, int]], ...]:
        if right == left + 1:
            return (frozenset(((left, right),)),)
        triangulations: list[frozenset[tuple[int, int]]] = []
        for middle in range(left + 1, right):
            edge = (left, right)
            for first_edges in all_edge_sets(left, middle):
                for second_edges in all_edge_sets(middle, right):
                    triangulations.append(first_edges | second_edges | frozenset((edge,)))
        return tuple(triangulations)

    def edge_squared_length(edge: tuple[int, int]) -> int:
        left, right = edge
        dx = points[left][0] - points[right][0]
        dy = points[left][1] - points[right][1]
        return dx * dx + dy * dy

    optimum: int | None = None
    for edges in all_edge_sets(0, len(points) - 1):
        score = max(edge_squared_length(edge) for edge in edges)
        if optimum is None or score < optimum:
            optimum = score
    return optimum if optimum is not None else 0


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _valid_polygon(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    return _enumerate_score(points)
