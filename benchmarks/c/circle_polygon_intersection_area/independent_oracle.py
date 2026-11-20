"""Independent polar-coordinate integration reference for circle/polygon area."""

from __future__ import annotations

from math import atan2, cos, pi, sin, sqrt, tau
from typing import Callable, Sequence

INVALID = -1.0e300
MAX_VERTICES = 16
MAX_COORDINATE = 32


def _parse(values: Sequence[int]) -> tuple[int, int, int, int, list[tuple[float, float]]] | None:
    if len(values) < 10 or len(values) > 37:
        return None
    n, cx, cy, radius = values[:4]
    if not 3 <= n <= MAX_VERTICES or len(values) != 4 + 2 * n:
        return None
    if not (-MAX_COORDINATE <= cx <= MAX_COORDINATE and
            -MAX_COORDINATE <= cy <= MAX_COORDINATE and 1 <= radius <= MAX_COORDINATE):
        return None
    absolute = [(values[4 + 2 * i], values[5 + 2 * i]) for i in range(n)]
    if any(not (-MAX_COORDINATE <= x <= MAX_COORDINATE and
                -MAX_COORDINATE <= y <= MAX_COORDINATE) for x, y in absolute):
        return None
    for i, (x, y) in enumerate(absolute):
        nx, ny = absolute[(i + 1) % n]
        dx, dy = nx - x, ny - y
        for j, (qx, qy) in enumerate(absolute):
            if j != i and j != (i + 1) % n and dx * (qy - y) - dy * (qx - x) <= 0:
                return None
        if dx * (cy - y) - dy * (cx - x) <= 0:
            return None
    return n, cx, cy, radius, [(float(x - cx), float(y - cy)) for x, y in absolute]


def _ray_boundary(points: list[tuple[float, float]], angle: float) -> float:
    rx, ry = cos(angle), sin(angle)
    nearest = float("inf")
    for index, (px, py) in enumerate(points):
        qx, qy = points[(index + 1) % len(points)]
        dx, dy = qx - px, qy - py
        denominator = rx * dy - ry * dx
        if abs(denominator) < 1e-15:
            continue
        along_edge = (ry * px - rx * py) / denominator
        if -1e-13 <= along_edge <= 1.0 + 1e-13:
            along_edge = min(1.0, max(0.0, along_edge))
            hit_x, hit_y = px + along_edge * dx, py + along_edge * dy
            distance = hit_x * rx + hit_y * ry
            if distance > 0.0 and distance < nearest:
                nearest = distance
    return nearest


def _events(points: list[tuple[float, float]], radius: float) -> list[float]:
    result = [0.0, tau]
    for px, py in points:
        result.append(atan2(py, px) % tau)
    radius_squared = radius * radius
    for index, (px, py) in enumerate(points):
        qx, qy = points[(index + 1) % len(points)]
        dx, dy = qx - px, qy - py
        aa = dx * dx + dy * dy
        bb = 2.0 * (px * dx + py * dy)
        cc = px * px + py * py - radius_squared
        discriminant = bb * bb - 4.0 * aa * cc
        if discriminant < 0.0:
            continue
        root = sqrt(discriminant)
        for fraction in ((-bb - root) / (2.0 * aa), (-bb + root) / (2.0 * aa)):
            if 0.0 <= fraction <= 1.0:
                hit_x, hit_y = px + fraction * dx, py + fraction * dy
                result.append(atan2(hit_y, hit_x) % tau)
    result.sort()
    unique: list[float] = []
    for value in result:
        if not unique or value - unique[-1] > 1e-13:
            unique.append(value)
    if unique[-1] != tau:
        unique.append(tau)
    if unique[0] != 0.0:
        unique.insert(0, 0.0)
    return unique


def _adaptive_simpson(function: Callable[[float], float], left: float, right: float,
                      f_left: float, f_middle: float, f_right: float,
                      whole: float, tolerance: float, depth: int) -> float:
    middle = (left + right) * 0.5
    left_middle = (left + middle) * 0.5
    right_middle = (middle + right) * 0.5
    f_left_middle = function(left_middle)
    f_right_middle = function(right_middle)
    left_area = (middle - left) * (f_left + 4.0 * f_left_middle + f_middle) / 6.0
    right_area = (right - middle) * (f_middle + 4.0 * f_right_middle + f_right) / 6.0
    refined = left_area + right_area
    error = refined - whole
    if depth == 0 or abs(error) <= 15.0 * tolerance:
        return refined + error / 15.0
    return (_adaptive_simpson(function, left, middle, f_left, f_left_middle,
                              f_middle, left_area, tolerance * 0.5, depth - 1) +
            _adaptive_simpson(function, middle, right, f_middle, f_right_middle,
                              f_right, right_area, tolerance * 0.5, depth - 1))


def circle_polygon_intersection_area(values: Sequence[int]) -> float:
    """Return intersection area via clipped radial distances and quadrature."""
    parsed = _parse(values)
    if parsed is None:
        return INVALID
    _n, _cx, _cy, radius_value, points = parsed
    radius = float(radius_value)
    radius_squared = radius * radius

    def radial_area(angle: float) -> float:
        reach = min(radius, _ray_boundary(points, angle))
        return 0.5 * reach * reach

    breaks = _events(points, radius)
    area = 0.0
    for left, right in zip(breaks, breaks[1:]):
        if right - left <= 1e-15:
            continue
        middle = (left + right) * 0.5
        f_left, f_middle, f_right = (radial_area(left), radial_area(middle), radial_area(right))
        whole = (right - left) * (f_left + 4.0 * f_middle + f_right) / 6.0
        area += _adaptive_simpson(radial_area, left, right, f_left, f_middle,
                                  f_right, whole, 2.0e-12, 22)
    return min(radius_squared * pi, area)


if __name__ == "__main__":
    raise SystemExit("This oracle is imported by static package tooling; no workload runner is bundled.")
