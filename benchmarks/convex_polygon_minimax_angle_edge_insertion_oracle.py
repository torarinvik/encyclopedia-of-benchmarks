"""Bounded edge-insertion reference for min-max-angle quadrilaterals."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

MIN_VERTICES = 3
MAX_VERTICES = 4
COORDINATE_LIMIT = 16
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1

Angle = tuple[int, int, int, int]
Triangle = tuple[int, int, int]


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


def _cross(points: tuple[tuple[int, int], ...], a: int, b: int, c: int) -> int:
    ax, ay = points[a]
    bx, by = points[b]
    cx, cy = points[c]
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)


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
    for a, b, c in combinations(range(n), 3):
        if _cross(points, a, b, c) == 0:
            return False
    for edge in range(n):
        following = (edge + 1) % n
        for vertex in range(n):
            if vertex in (edge, following):
                continue
            if orientation * _cross(points, edge, following, vertex) <= 0:
                return False
    return True


def _angle_components(points: tuple[tuple[int, int], ...], angle: Angle) -> tuple[int, int]:
    a, b, c, vertex = angle
    center = (a, b, c)[vertex]
    others = [item for item in (a, b, c) if item != center]
    ox, oy = points[center]
    ux, uy = points[others[0]][0] - ox, points[others[0]][1] - oy
    vx, vy = points[others[1]][0] - ox, points[others[1]][1] - oy
    dot = ux * vx + uy * vy
    denominator = (ux * ux + uy * uy) * (vx * vx + vy * vy)
    return dot, denominator


def _angle_cmp(points: tuple[tuple[int, int], ...], left: Angle, right: Angle) -> int:
    """Compare angles in [0, pi] without floating point or square roots."""
    left_dot, left_den = _angle_components(points, left)
    right_dot, right_den = _angle_components(points, right)
    if left_dot == 0 or right_dot == 0:
        if left_dot == right_dot:
            return 0
        if left_dot == 0:
            return 1 if right_dot > 0 else -1
        return -1 if left_dot > 0 else 1
    if (left_dot < 0) != (right_dot < 0):
        return 1 if left_dot < 0 else -1
    left_scaled = left_dot * left_dot * right_den
    right_scaled = right_dot * right_dot * left_den
    if left_dot > 0:
        if left_scaled == right_scaled:
            return 0
        return -1 if left_scaled > right_scaled else 1
    if left_scaled == right_scaled:
        return 0
    return 1 if left_scaled > right_scaled else -1


def _triangle_max(points: tuple[tuple[int, int], ...], triangle: Triangle) -> Angle:
    a, b, c = sorted(triangle)
    best = (a, b, c, 0)
    for vertex in (1, 2):
        candidate = (a, b, c, vertex)
        comparison = _angle_cmp(points, candidate, best)
        if comparison > 0 or (comparison == 0 and (a, b, c)[vertex] < (a, b, c)[best[3]]):
            best = candidate
    return best


def _triangulation_max(points: tuple[tuple[int, int], ...],
                       triangles: tuple[Triangle, ...]) -> Angle:
    best = _triangle_max(points, triangles[0])
    for triangle in triangles[1:]:
        candidate = _triangle_max(points, triangle)
        if _angle_cmp(points, candidate, best) > 0:
            best = candidate
    return best


def _properly_crosses(points: tuple[tuple[int, int], ...],
                      a: int, b: int, c: int, d: int) -> bool:
    return (_cross(points, a, b, c) * _cross(points, a, b, d) < 0
            and _cross(points, c, d, a) * _cross(points, c, d, b) < 0)


def _angle_rank(points: tuple[tuple[int, int], ...], target: Angle) -> int:
    distinct_lower: list[Angle] = []
    n = len(points)
    for a, b, c in combinations(range(n), 3):
        for vertex in range(3):
            candidate = (a, b, c, vertex)
            if _angle_cmp(points, candidate, target) >= 0:
                continue
            if not any(_angle_cmp(points, candidate, previous) == 0
                       for previous in distinct_lower):
                distinct_lower.append(candidate)
    return len(distinct_lower) + 1


def _edge_insertion(points: tuple[tuple[int, int], ...]) -> Angle:
    if len(points) == 3:
        return _triangle_max(points, ((0, 1, 2),))
    current: tuple[Triangle, ...] = ((0, 1, 2), (0, 2, 3))
    current_worst = _triangulation_max(points, current)
    # M1 selects largest-angle occurrences; M2 tests the unique remaining point.
    for triangle in current:
        a, b, c = sorted(triangle)
        for vertex in range(3):
            candidate = (a, b, c, vertex)
            if _angle_cmp(points, candidate, current_worst) != 0:
                continue
            q = (a, b, c)[vertex]
            p, r = sorted(item for item in (a, b, c) if item != q)
            s = next(item for item in range(4) if item not in (p, q, r))
            if not _properly_crosses(points, q, s, p, r):
                continue
            inserted: tuple[Triangle, ...] = (tuple(sorted((q, s, p))), tuple(sorted((q, s, r))))
            inserted_worst = _triangulation_max(points, inserted)
            if _angle_cmp(points, inserted_worst, current_worst) < 0:
                current_worst = inserted_worst
                return current_worst
    return current_worst


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    return _angle_rank(points, _edge_insertion(points))
