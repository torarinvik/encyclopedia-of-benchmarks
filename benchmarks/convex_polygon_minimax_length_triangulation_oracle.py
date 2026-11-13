"""Interval minimax oracle for convex-polygon min-max edge triangulation."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 3
MAX_VERTICES = 12
COORDINATE_LIMIT = 1000
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, int], ...] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES or input_length != 1 + 2 * n:
        return None
    points = tuple((values[1 + 2 * i], values[2 + 2 * i]) for i in range(n))
    if any(abs(x) > COORDINATE_LIMIT or abs(y) > COORDINATE_LIMIT for x, y in points):
        return None
    if not _strictly_convex_in_order(points):
        return None
    return points


def _strictly_convex_in_order(points: tuple[tuple[int, int], ...]) -> bool:
    n = len(points)
    area_twice = sum(
        points[i][0] * points[(i + 1) % n][1]
        - points[i][1] * points[(i + 1) % n][0]
        for i in range(n)
    )
    if area_twice == 0:
        return False
    orientation = 1 if area_twice > 0 else -1
    for edge in range(n):
        x0, y0 = points[edge]
        x1, y1 = points[(edge + 1) % n]
        dx, dy = x1 - x0, y1 - y0
        for vertex, (x, y) in enumerate(points):
            if vertex == edge or vertex == (edge + 1) % n:
                continue
            cross = dx * (y - y0) - dy * (x - x0)
            if orientation * cross <= 0:
                return False
    return True


def _squared_length(points: tuple[tuple[int, int], ...], left: int, right: int) -> int:
    dx = points[left][0] - points[right][0]
    dy = points[left][1] - points[right][1]
    return dx * dx + dy * dy


def _interval_minimax(points: tuple[tuple[int, int], ...]) -> int:
    n = len(points)
    best = [[0] * n for _ in range(n)]
    for left in range(n - 1):
        best[left][left + 1] = _squared_length(points, left, left + 1)
    for span in range(2, n):
        for left in range(n - span):
            right = left + span
            boundary = _squared_length(points, left, right)
            optimum: int | None = None
            for middle in range(left + 1, right):
                candidate = max(best[left][middle], best[middle][right], boundary)
                if optimum is None or candidate < optimum:
                    optimum = candidate
            best[left][right] = optimum if optimum is not None else boundary
    return best[0][n - 1]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    return _interval_minimax(points)
