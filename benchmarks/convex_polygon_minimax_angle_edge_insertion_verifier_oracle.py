"""Independent exhaustive triangulation reference for the bounded angle profile."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

MIN_VERTICES = 3
MAX_VERTICES = 4
COORDINATE_LIMIT = 16
MAX_PARSEABLE_INPUT_LENGTH = 10
INVALID_RESULT = -1
Angle = tuple[int, int, int, int]


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
    area_twice = sum(
        points[i][0] * points[(i + 1) % n][1]
        - points[i][1] * points[(i + 1) % n][0]
        for i in range(n)
    )
    if area_twice == 0:
        return None
    orientation = 1 if area_twice > 0 else -1
    if any(_orientation(points, a, b, c) == 0 for a, b, c in combinations(range(n), 3)):
        return None
    for edge in range(n):
        following = (edge + 1) % n
        for vertex in range(n):
            if vertex not in (edge, following) and orientation * _orientation(points, edge, following, vertex) <= 0:
                return None
    return points


def _orientation(points: tuple[tuple[int, int], ...], a: int, b: int, c: int) -> int:
    ax, ay = points[a]
    bx, by = points[b]
    cx, cy = points[c]
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)


def _compare_angles(points: tuple[tuple[int, int], ...], first: Angle, second: Angle) -> int:
    def cosine_parts(ref: Angle) -> tuple[int, int]:
        a, b, c, position = ref
        center = (a, b, c)[position]
        endpoints = tuple(vertex for vertex in (a, b, c) if vertex != center)
        cx, cy = points[center]
        ux, uy = points[endpoints[0]][0] - cx, points[endpoints[0]][1] - cy
        vx, vy = points[endpoints[1]][0] - cx, points[endpoints[1]][1] - cy
        return ux * vx + uy * vy, (ux * ux + uy * uy) * (vx * vx + vy * vy)

    d1, z1 = cosine_parts(first)
    d2, z2 = cosine_parts(second)
    # Compare signs first, then compare squared cosine magnitudes by cross products.
    if d1 == 0 or d2 == 0:
        if d1 == d2:
            return 0
        if d1 == 0:
            return 1 if d2 > 0 else -1
        return -1 if d1 > 0 else 1
    if (d1 < 0) != (d2 < 0):
        return 1 if d1 < 0 else -1
    left_product, right_product = d1 * d1 * z2, d2 * d2 * z1
    if left_product == right_product:
        return 0
    if d1 < 0:
        return 1 if left_product > right_product else -1
    return -1 if left_product > right_product else 1


def _largest_in_triangle(points: tuple[tuple[int, int], ...], triangle: tuple[int, int, int]) -> Angle:
    a, b, c = sorted(triangle)
    best = (a, b, c, 0)
    for position in (1, 2):
        candidate = (a, b, c, position)
        if _compare_angles(points, candidate, best) > 0:
            best = candidate
    return best


def _triangulation_worst(points: tuple[tuple[int, int], ...],
                         triangles: tuple[tuple[int, int, int], ...]) -> Angle:
    worst = _largest_in_triangle(points, triangles[0])
    for triangle in triangles[1:]:
        candidate = _largest_in_triangle(points, triangle)
        if _compare_angles(points, candidate, worst) > 0:
            worst = candidate
    return worst


def _rank_of(points: tuple[tuple[int, int], ...], target: Angle) -> int:
    unique_smaller: list[Angle] = []
    for a, b, c in combinations(range(len(points)), 3):
        for position in range(3):
            candidate = (a, b, c, position)
            if _compare_angles(points, candidate, target) >= 0:
                continue
            if all(_compare_angles(points, candidate, existing) != 0 for existing in unique_smaller):
                unique_smaller.append(candidate)
    return len(unique_smaller) + 1


def _enumerate_triangulations(n: int) -> tuple[tuple[tuple[int, int, int], ...], ...]:
    if n == 3:
        return (((0, 1, 2),),)
    # For a convex quadrilateral the two recursive root splits are the two diagonals.
    return (
        ((0, 1, 2), (0, 2, 3)),
        ((0, 1, 3), (1, 2, 3)),
    )


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    triangulations = _enumerate_triangulations(len(points))
    best = _triangulation_worst(points, triangulations[0])
    for triangles in triangulations[1:]:
        candidate = _triangulation_worst(points, triangles)
        if _compare_angles(points, candidate, best) < 0:
            best = candidate
    return _rank_of(points, best)
