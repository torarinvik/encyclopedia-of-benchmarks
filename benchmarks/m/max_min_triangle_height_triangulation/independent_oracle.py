"""Exhaustive triangulation reference for max-min triangle height."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
from functools import lru_cache
from itertools import combinations

MIN_VERTICES = 3
MAX_VERTICES = 5
COORDINATE_LIMIT = 8
MAX_PARSEABLE_INPUT_LENGTH = 12
INVALID_RESULT = -1
Point = tuple[int, int]
Triangle = tuple[int, int, int]


def _orientation(a: Point, b: Point, c: Point) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _read_points(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None) -> tuple[Point, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES or input_length != 1 + 2 * n:
        return None
    points = tuple((values[1 + 2 * k], values[2 + 2 * k]) for k in range(n))
    if any(max(abs(x), abs(y)) > COORDINATE_LIMIT for x, y in points):
        return None
    if len(set(points)) != n:
        return None
    twice_area = sum(points[k][0] * points[(k + 1) % n][1]
                     - points[k][1] * points[(k + 1) % n][0] for k in range(n))
    if twice_area <= 0:
        return None
    if any(_orientation(points[a], points[b], points[c]) == 0
           for a, b, c in combinations(range(n), 3)):
        return None
    for edge in range(n):
        following = (edge + 1) % n
        if any(_orientation(points[edge], points[following], points[v]) <= 0
               for v in range(n) if v not in (edge, following)):
            return None
    return points


def _height_squared(points: tuple[Point, ...], triangle: Triangle) -> Fraction:
    a, b, c = (points[i] for i in triangle)
    twice_area = abs(_orientation(a, b, c))
    side_squares = ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2,
                    (b[0] - c[0]) ** 2 + (b[1] - c[1]) ** 2,
                    (c[0] - a[0]) ** 2 + (c[1] - a[1]) ** 2)
    return min(Fraction(twice_area * twice_area, side) for side in side_squares)


def _score(points: tuple[Point, ...], triangles: tuple[Triangle, ...]) -> tuple[Fraction, int]:
    heights = [_height_squared(points, triangle) for triangle in triangles]
    minimum = min(heights)
    return minimum, heights.count(minimum)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _read_points(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    n = len(points)

    @lru_cache(maxsize=None)
    def triangulations(left: int, right: int) -> tuple[tuple[Triangle, ...], ...]:
        if right - left < 2:
            return ((),)
        all_splits: list[tuple[Triangle, ...]] = []
        for middle in range(left + 1, right):
            root = (left, middle, right)
            for before in triangulations(left, middle):
                for after in triangulations(middle, right):
                    all_splits.append((root,) + before + after)
        return tuple(all_splits)

    best: tuple[Fraction, int] | None = None
    for candidate in triangulations(0, n - 1):
        score = _score(points, candidate)
        if best is None or score[0] > best[0] or (
                score[0] == best[0] and score[1] < best[1]):
            best = score
    assert best is not None
    return best[0].numerator * 513 + best[0].denominator
