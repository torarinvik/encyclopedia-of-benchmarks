"""Independent exhaustive triangulation oracle for lifted min-max slope."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

INVALID_RESULT = -1
MAX_VERTICES = 4
MAX_PARSEABLE_INPUT_LENGTH = 14


def _valid(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, int, int], ...] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (tuple, list)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n = values[0]
    if n not in (3, 4) or input_length != 1 + 3 * n:
        return None
    p = tuple((values[1 + 3 * i], values[2 + 3 * i], values[3 + 3 * i]) for i in range(n))
    if any(abs(c) > 8 for point in p for c in point):
        return None
    area = sum(p[i][0] * p[(i + 1) % n][1] - p[i][1] * p[(i + 1) % n][0] for i in range(n))
    if area == 0:
        return None
    sign = 1 if area > 0 else -1
    for i in range(n):
        j = (i + 1) % n
        for k in range(n):
            if k in (i, j):
                continue
            cross = (p[j][0] - p[i][0]) * (p[k][1] - p[i][1]) - (p[j][1] - p[i][1]) * (p[k][0] - p[i][0])
            if sign * cross <= 0:
                return None
    if n == 4:
        u = tuple(p[1][k] - p[0][k] for k in range(3))
        v = tuple(p[2][k] - p[0][k] for k in range(3))
        w = tuple(p[3][k] - p[0][k] for k in range(3))
        det = (u[0] * (v[1] * w[2] - v[2] * w[1])
               - u[1] * (v[0] * w[2] - v[2] * w[0])
               + u[2] * (v[0] * w[1] - v[1] * w[0]))
        if det == 0:
            return None
    return p


def _slope(p: tuple[tuple[int, int, int], ...], tri: tuple[int, int, int]) -> tuple[int, int]:
    a, b, c = tri
    x0, y0, z0 = p[a]
    x1, y1, z1 = p[b]
    x2, y2, z2 = p[c]
    dx1, dy1, dz1 = x1 - x0, y1 - y0, z1 - z0
    dx2, dy2, dz2 = x2 - x0, y2 - y0, z2 - z0
    den0 = dx1 * dy2 - dx2 * dy1
    gx = dz1 * dy2 - dz2 * dy1
    gy = dx1 * dz2 - dz1 * dx2
    return gx * gx + gy * gy, den0 * den0


def _cmp(left: tuple[int, int], right: tuple[int, int]) -> int:
    x = left[0] * right[1] - right[0] * left[1]
    return (x > 0) - (x < 0)


def _objective(p: tuple[tuple[int, int, int], ...], triangulation: tuple[tuple[int, int, int], ...]) -> tuple[int, int]:
    slopes = [_slope(p, t) for t in triangulation]
    return _maximum(slopes)


def _maximum(slopes: list[tuple[int, int]]) -> tuple[int, int]:
    best = slopes[0]
    for candidate in slopes[1:]:
        if _cmp(candidate, best) > 0:
            best = candidate
    return best


def _rank(p: tuple[tuple[int, int, int], ...], target: tuple[int, int]) -> int:
    distinct: list[tuple[int, int]] = []
    for tri in combinations(range(len(p)), 3):
        item = _slope(p, tri)
        if _cmp(item, target) < 0 and not any(_cmp(item, old) == 0 for old in distinct):
            distinct.append(item)
    return len(distinct) + 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    p = _valid(values, input_is_null, input_length)
    if p is None:
        return INVALID_RESULT
    options = [((0, 1, 2),)] if len(p) == 3 else [((0, 1, 2), (0, 2, 3)), ((0, 1, 3), (1, 2, 3))]
    optimum = _objective(p, options[0])
    for triangulation in options[1:]:
        candidate = _objective(p, triangulation)
        if _cmp(candidate, optimum) < 0:
            optimum = candidate
    return _rank(p, optimum)
