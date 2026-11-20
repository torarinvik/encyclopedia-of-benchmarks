"""Independent exact exhaustive verifier for min-max eccentricity triangulations."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
from functools import lru_cache
from itertools import combinations

MIN_N = 3
MAX_N = 6
COORD_LIMIT = 4
MAX_PARSEABLE_LENGTH = 14
INVALID_RESULT = -1
Point = tuple[int, int]
Triangle = tuple[int, int, int]


def _orientation(a: Point, b: Point, c: Point) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[Point, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 1 <= input_length <= MAX_PARSEABLE_LENGTH):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values):
        return None
    count = values[0]
    if not MIN_N <= count <= MAX_N or input_length != 1 + 2 * count:
        return None
    points = tuple((values[1 + 2 * i], values[2 + 2 * i]) for i in range(count))
    if any(abs(x) > COORD_LIMIT or abs(y) > COORD_LIMIT for x, y in points):
        return None
    area = sum(points[i][0] * points[(i + 1) % count][1]
               - points[i][1] * points[(i + 1) % count][0] for i in range(count))
    if area == 0:
        return None
    direction = 1 if area > 0 else -1
    if any(_orientation(points[a], points[b], points[c]) == 0
           for a, b, c in combinations(range(count), 3)):
        return None
    for edge in range(count):
        following = (edge + 1) % count
        if any(direction * _orientation(points[edge], points[following], vertex) <= 0
               for vertex in range(count) if vertex not in (edge, following)):
            return None
    return points


def _circumcenter(points: tuple[Point, ...], triangle: Triangle) -> tuple[int, int, int]:
    a, b, c = (points[index] for index in triangle)
    aa = a[0] * a[0] + a[1] * a[1]
    bb = b[0] * b[0] + b[1] * b[1]
    cc = c[0] * c[0] + c[1] * c[1]
    denominator = 2 * _orientation(a, b, c)
    center_x = aa * (b[1] - c[1]) + bb * (c[1] - a[1]) + cc * (a[1] - b[1])
    center_y = aa * (c[0] - b[0]) + bb * (a[0] - c[0]) + cc * (b[0] - a[0])
    if denominator < 0:
        return -center_x, -center_y, -denominator
    return center_x, center_y, denominator


def _eccentricity_squared(points: tuple[Point, ...], triangle: Triangle) -> Fraction:
    center_x, center_y, denominator = _circumcenter(points, triangle)
    vertices = tuple(points[index] for index in triangle)
    orientation = _orientation(*vertices)
    inside = True
    for i in range(3):
        px, py = vertices[i]
        qx, qy = vertices[(i + 1) % 3]
        side = ((qx - px) * (center_y - py * denominator)
                - (qy - py) * (center_x - px * denominator))
        if side * orientation < 0:
            inside = False
            break
    if inside:
        return Fraction(0, 1)

    distances: list[Fraction] = []
    for i in range(3):
        px, py = vertices[i]
        qx, qy = vertices[(i + 1) % 3]
        vx, vy = qx - px, qy - py
        dx, dy = center_x - px * denominator, center_y - py * denominator
        length_squared = vx * vx + vy * vy
        projection = vx * dx + vy * dy
        if projection <= 0:
            distances.append(Fraction(dx * dx + dy * dy, denominator * denominator))
        elif projection >= length_squared * denominator:
            ex, ey = center_x - qx * denominator, center_y - qy * denominator
            distances.append(Fraction(ex * ex + ey * ey, denominator * denominator))
        else:
            cross = vx * dy - vy * dx
            distances.append(Fraction(cross * cross,
                                      length_squared * denominator * denominator))
    return min(distances)


def _triangulations(count: int) -> tuple[tuple[Triangle, ...], ...]:
    @lru_cache(maxsize=None)
    def interval(left: int, right: int) -> tuple[tuple[Triangle, ...], ...]:
        if right - left < 2:
            return ((),)
        candidates: list[tuple[Triangle, ...]] = []
        for split in range(left + 1, right):
            for before in interval(left, split):
                for after in interval(split, right):
                    candidates.append(((left, split, right),) + before + after)
        return tuple(candidates)
    return interval(0, count - 1)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _read(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    scores = [tuple(_eccentricity_squared(points, triangle) for triangle in triangulation)
              for triangulation in _triangulations(len(points))]
    optimum = min(max(triangle_scores) for triangle_scores in scores)
    distinct_lower: list[Fraction] = []
    for triangle in combinations(range(len(points)), 3):
        score = _eccentricity_squared(points, triangle)
        if score < optimum and score not in distinct_lower:
            distinct_lower.append(score)
    return len(distinct_lower) + 1
