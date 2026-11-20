"""Clean-room bounded edge-insertion reference for lifted min-max slope."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

MIN_VERTICES = 3
MAX_VERTICES = 4
COORDINATE_LIMIT = 8
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1

Triangle = tuple[int, int, int]


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, int, int], ...] | None:
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
    if not MIN_VERTICES <= n <= MAX_VERTICES or input_length != 1 + 3 * n:
        return None
    points = tuple(tuple(values[1 + 3 * i + k] for k in range(3)) for i in range(n))
    if any(abs(value) > COORDINATE_LIMIT for point in points for value in point):
        return None
    if not _strictly_convex_xy(points):
        return None
    if n == 4 and _volume6(points) == 0:
        return None
    return points


def _orient_xy(points: tuple[tuple[int, int, int], ...], a: int, b: int, c: int) -> int:
    ax, ay, _ = points[a]
    bx, by, _ = points[b]
    cx, cy, _ = points[c]
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)


def _strictly_convex_xy(points: tuple[tuple[int, int, int], ...]) -> bool:
    n = len(points)
    area2 = sum(points[i][0] * points[(i + 1) % n][1] - points[i][1] * points[(i + 1) % n][0]
                for i in range(n))
    if area2 == 0:
        return False
    orientation = 1 if area2 > 0 else -1
    if any(_orient_xy(points, a, b, c) == 0 for a, b, c in combinations(range(n), 3)):
        return False
    for edge in range(n):
        following = (edge + 1) % n
        for vertex in range(n):
            if vertex not in (edge, following) and orientation * _orient_xy(points, edge, following, vertex) <= 0:
                return False
    return True


def _volume6(points: tuple[tuple[int, int, int], ...]) -> int:
    origin = points[0]
    vectors = [tuple(points[i][k] - origin[k] for k in range(3)) for i in (1, 2, 3)]
    a, b, c = vectors
    return (a[0] * (b[1] * c[2] - b[2] * c[1])
            - a[1] * (b[0] * c[2] - b[2] * c[0])
            + a[2] * (b[0] * c[1] - b[1] * c[0]))


def _slope_parts(points: tuple[tuple[int, int, int], ...], triangle: Triangle) -> tuple[int, int]:
    a, b, c = triangle
    x0, y0, z0 = points[a]
    x1, y1, z1 = points[b]
    x2, y2, z2 = points[c]
    dx1, dy1, dz1 = x1 - x0, y1 - y0, z1 - z0
    dx2, dy2, dz2 = x2 - x0, y2 - y0, z2 - z0
    det = dx1 * dy2 - dx2 * dy1
    gx_num = dz1 * dy2 - dz2 * dy1
    gy_num = dx1 * dz2 - dx2 * dz1
    return gx_num * gx_num + gy_num * gy_num, det * det


def _slope_cmp(points: tuple[tuple[int, int, int], ...], left: Triangle, right: Triangle) -> int:
    left_num, left_den = _slope_parts(points, left)
    right_num, right_den = _slope_parts(points, right)
    lhs, rhs = left_num * right_den, right_num * left_den
    return (lhs > rhs) - (lhs < rhs)


def _triangle_slope(points: tuple[tuple[int, int, int], ...], triangle: Triangle) -> Triangle:
    return tuple(sorted(triangle))


def _triangulation_worst(points: tuple[tuple[int, int, int], ...],
                         triangles: tuple[Triangle, ...]) -> Triangle:
    worst = _triangle_slope(points, triangles[0])
    for triangle in triangles[1:]:
        candidate = _triangle_slope(points, triangle)
        if _slope_cmp(points, candidate, worst) > 0:
            worst = candidate
    return worst


def _anchor(points: tuple[tuple[int, int, int], ...], triangle: Triangle, vertex: int) -> bool:
    a, b, c = triangle
    x0, y0, z0 = points[a]
    x1, y1, z1 = points[b]
    x2, y2, z2 = points[c]
    dx1, dy1, dz1 = x1 - x0, y1 - y0, z1 - z0
    dx2, dy2, dz2 = x2 - x0, y2 - y0, z2 - z0
    det = dx1 * dy2 - dx2 * dy1
    gx_num = dz1 * dy2 - dz2 * dy1
    gy_num = dx1 * dz2 - dx2 * dz1
    if gx_num == 0 and gy_num == 0:
        return False
    direction = (-gx_num * (1 if det > 0 else -1), -gy_num * (1 if det > 0 else -1))
    others = [item for item in triangle if item != vertex]
    qx, qy, _ = points[vertex]
    ux, uy, _ = points[others[0]]
    vx, vy, _ = points[others[1]]
    u = (ux - qx, uy - qy)
    v = (vx - qx, vy - qy)
    orient = u[0] * v[1] - u[1] * v[0]
    cross_u_d = u[0] * direction[1] - u[1] * direction[0]
    cross_d_v = direction[0] * v[1] - direction[1] * v[0]
    sign = 1 if orient > 0 else -1
    return sign * cross_u_d >= 0 and sign * cross_d_v >= 0


def _properly_crosses(points: tuple[tuple[int, int, int], ...],
                      a: int, b: int, c: int, d: int) -> bool:
    return (_orient_xy(points, a, b, c) * _orient_xy(points, a, b, d) < 0
            and _orient_xy(points, c, d, a) * _orient_xy(points, c, d, b) < 0)


def _slope_rank(points: tuple[tuple[int, int, int], ...], target: Triangle) -> int:
    distinct_lower: list[Triangle] = []
    n = len(points)
    for triangle in combinations(range(n), 3):
        if _slope_cmp(points, triangle, target) >= 0:
            continue
        if not any(_slope_cmp(points, triangle, previous) == 0 for previous in distinct_lower):
            distinct_lower.append(triangle)
    return len(distinct_lower) + 1


def _edge_insertion(points: tuple[tuple[int, int, int], ...]) -> Triangle:
    if len(points) == 3:
        return (0, 1, 2)
    current: tuple[Triangle, ...] = ((0, 1, 2), (0, 2, 3))
    current_worst = _triangulation_worst(points, current)
    for triangle in current:
        ordered = tuple(sorted(triangle))
        if _slope_cmp(points, ordered, current_worst) != 0:
            continue
        for q in ordered:
            if not _anchor(points, ordered, q):
                continue
            opposite = tuple(vertex for vertex in ordered if vertex != q)
            s = next(vertex for vertex in range(4) if vertex not in ordered)
            if not _properly_crosses(points, q, s, opposite[0], opposite[1]):
                continue
            inserted: tuple[Triangle, ...] = (
                tuple(sorted((q, s, opposite[0]))),
                tuple(sorted((q, s, opposite[1]))),
            )
            replacement = _triangulation_worst(points, inserted)
            if _slope_cmp(points, replacement, current_worst) < 0:
                return replacement
    return current_worst


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    return _slope_rank(points, _edge_insertion(points))
