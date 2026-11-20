"""Exact-angle greedy reference for max-min length triangulation."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

MIN_VERTICES = 3
MAX_VERTICES = 6
COORDINATE_LIMIT = 8
MAX_VALID_INPUT_LENGTH = 13
MAX_PARSEABLE_INPUT_LENGTH = 14
MAX_STEPS = 4 * MAX_VERTICES
INVALID_RESULT = -1

Point = tuple[int, int]


def _cross(a: Point, b: Point, c: Point) -> int:
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
    points = tuple((values[1 + 2 * i], values[2 + 2 * i]) for i in range(n))
    if any(max(abs(x), abs(y)) > COORDINATE_LIMIT for x, y in points):
        return None
    if len(set(points)) != n:
        return None
    twice_area = sum(points[i][0] * points[(i + 1) % n][1]
                     - points[i][1] * points[(i + 1) % n][0] for i in range(n))
    if twice_area <= 0:
        return None
    if any(_cross(points[a], points[b], points[c]) == 0
           for a, b, c in combinations(range(n), 3)):
        return None
    for edge in range(n):
        following = (edge + 1) % n
        if any(_cross(points[edge], points[following], points[v]) <= 0
               for v in range(n) if v not in (edge, following)):
            return None
    return points


def _distance_squared(a: Point, b: Point) -> int:
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2


def _angle_at_least_sixty(p: Point, q: Point, r: Point) -> bool:
    ux, uy = p[0] - q[0], p[1] - q[1]
    vx, vy = r[0] - q[0], r[1] - q[1]
    dot = ux * vx + uy * vy
    if dot <= 0:
        return True
    return 4 * dot * dot <= (ux * ux + uy * uy) * (vx * vx + vy * vy)


def _diagonal_bit(n: int, a: int, b: int) -> int:
    left, right = sorted((a, b))
    bit = 0
    for first in range(n):
        for second in range(first + 2, n):
            if first == 0 and second == n - 1:
                continue
            if (first, second) == (left, right):
                return bit
            bit += 1
    return -1


def _greedy(points: tuple[Point, ...]) -> int | None:
    n = len(points)
    next_vertex = [(i + 1) % n for i in range(n)]
    active_count = n
    p = 0
    q = next_vertex[p]
    r = next_vertex[q]
    shortest = min(_distance_squared(points[i], points[(i + 1) % n])
                   for i in range(n))
    diagonal_mask = 0
    steps = 0
    while active_count > 3:
        steps += 1
        if steps > MAX_STEPS:
            return None
        if _angle_at_least_sixty(points[p], points[q], points[r]):
            shortest = min(shortest, _distance_squared(points[p], points[r]))
            bit = _diagonal_bit(n, p, r)
            if bit < 0:
                return None
            diagonal_mask |= 1 << bit
            next_vertex[p] = r
            active_count -= 1
            q = r
            r = next_vertex[r]
        else:
            p, q, r = q, r, next_vertex[r]
    return shortest * 512 + diagonal_mask


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _read_points(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    result = _greedy(points)
    return INVALID_RESULT if result is None else result
