"""Independent empty-circumcircle oracle for the bounded Olden Voronoi dual."""

from __future__ import annotations

from itertools import combinations
from math import floor

MAX_POINTS = 5
MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS
SCALE = 1_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _cross(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (a[0] - c[0]) * (b[1] - c[1]) - (b[0] - c[0]) * (a[1] - c[1])


def _incircle_det(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int], d: tuple[int, int]) -> int:
    adx, ady = a[0] - d[0], a[1] - d[1]
    bdx, bdy = b[0] - d[0], b[1] - d[1]
    cdx, cdy = c[0] - d[0], c[1] - d[1]
    anorm = a[0] * a[0] + a[1] * a[1]
    bnorm = b[0] * b[0] + b[1] * b[1]
    cnorm = c[0] * c[0] + c[1] * c[1]
    dnorm = d[0] * d[0] + d[1] * d[1]
    return ((anorm - dnorm) * (bdx * cdy - bdy * cdx)
            + (bnorm - dnorm) * (cdx * ady - cdy * adx)
            + (cnorm - dnorm) * (adx * bdy - ady * bdx))


def _circumcenter(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> tuple[float, float]:
    vx, vy = b[0] - a[0], b[1] - a[1]
    wx, wy = c[0] - a[0], c[1] - a[1]
    d3 = vx * wy - vy * wx
    d2 = -2.0 * d3
    d4 = (c[0] - b[0]) * wx + (c[1] - b[1]) * wy
    return (0.5 * (a[0] + b[0]) + (d4 / d2) * vy,
            0.5 * (a[1] + b[1]) - (d4 / d2) * vx)


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) not in (7, 11):
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    count = values[0]
    if count not in (3, 5) or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    coordinates = values[1:]
    if any(value < -8 or value > 8 for value in coordinates):
        return INVALID_RESULT
    points = [(coordinates[i], coordinates[i + 1]) for i in range(0, len(coordinates), 2)]
    if any(points[i][0] >= points[i + 1][0] for i in range(count - 1)):
        return INVALID_RESULT
    if any(_cross(a, b, c) == 0 for a, b, c in combinations(points, 3)):
        return INVALID_RESULT
    if count == 5 and any(_incircle_det(a, b, c, d) == 0
                          for a, b, c, d in combinations(points, 4)):
        return INVALID_RESULT

    triangles: list[tuple[int, int, int]] = []
    centers: list[tuple[float, float]] = []
    for triple in combinations(range(count), 3):
        a, b, c = (points[index] for index in triple)
        orientation = _cross(a, b, c)
        empty = True
        for other in range(count):
            if other in triple:
                continue
            determinant = _incircle_det(a, b, c, points[other])
            if determinant * orientation > 0:
                empty = False
                break
        if empty:
            triangles.append(triple)
            centers.append(_circumcenter(a, b, c))

    edge_incidence: dict[tuple[int, int], int] = {}
    for a, b, c in triangles:
        for edge in ((a, b), (a, c), (b, c)):
            edge = tuple(sorted(edge))
            edge_incidence[edge] = edge_incidence.get(edge, 0) + 1
    center_projection = sum(floor(x * SCALE + 0.5) + 2 * floor(y * SCALE + 0.5)
                            for x, y in centers)
    finite_dual_edges = sum(1 for incidence in edge_incidence.values() if incidence == 2)
    boundary_rays = sum(1 for incidence in edge_incidence.values() if incidence == 1)
    return center_projection + 100 * len(triangles) + 10 * finite_dual_edges + boundary_rays + len(edge_incidence)
