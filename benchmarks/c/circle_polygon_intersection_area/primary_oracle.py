"""Reference the edge-sector circle/polygon area algorithm."""

from __future__ import annotations

from math import atan2, sqrt
from typing import Sequence

INVALID = -1.0e300
MAX_VERTICES = 16
MAX_COORDINATE = 32


def _parse(values: Sequence[int]) -> tuple[int, int, int, int, list[tuple[int, int]]] | None:
    if len(values) < 10 or len(values) > 37:
        return None
    n, cx, cy, radius = values[:4]
    if not 3 <= n <= MAX_VERTICES or len(values) != 4 + 2 * n:
        return None
    if not (-MAX_COORDINATE <= cx <= MAX_COORDINATE and
            -MAX_COORDINATE <= cy <= MAX_COORDINATE and 1 <= radius <= MAX_COORDINATE):
        return None
    points = [(values[4 + 2 * i], values[5 + 2 * i]) for i in range(n)]
    if any(not (-MAX_COORDINATE <= x <= MAX_COORDINATE and
                -MAX_COORDINATE <= y <= MAX_COORDINATE) for x, y in points):
        return None

    for i, (x, y) in enumerate(points):
        nx, ny = points[(i + 1) % n]
        dx, dy = nx - x, ny - y
        for j, (qx, qy) in enumerate(points):
            if j != i and j != (i + 1) % n and dx * (qy - y) - dy * (qx - x) <= 0:
                return None
        if dx * (cy - y) - dy * (cx - x) <= 0:
            return None
    return n, cx, cy, radius, points


def circle_polygon_intersection_area(values: Sequence[int]) -> float:
    """Return the intersection area, or the invalid-input sentinel."""
    parsed = _parse(values)
    if parsed is None:
        return INVALID
    n, cx, cy, radius, points = parsed
    radius_squared = float(radius * radius)
    total = 0.0

    for i, (x0, y0) in enumerate(points):
        x1, y1 = points[(i + 1) % n]
        px, py = float(x0 - cx), float(y0 - cy)
        qx, qy = float(x1 - cx), float(y1 - cy)
        dx, dy = qx - px, qy - py
        length_squared = dx * dx + dy * dy
        projection = px * dx + py * dy
        constant = px * px + py * py - radius_squared
        discriminant = projection * projection - length_squared * constant
        angle = atan2(px * qy - py * qx, px * qx + py * qy)

        if discriminant <= 0.0:
            total += radius_squared * angle
            continue

        root = sqrt(discriminant)
        first = (-projection - root) / length_squared
        second = (-projection + root) / length_squared
        if second < 0.0 or first > 1.0:
            total += radius_squared * angle
            continue

        start = max(0.0, first)
        stop = min(1.0, second)
        ux, uy = px + start * dx, py + start * dy
        vx, vy = px + stop * dx, py + stop * dy
        first_sector = atan2(px * uy - py * ux, px * ux + py * uy)
        last_sector = atan2(vx * qy - vy * qx, vx * qx + vy * qy)
        total += radius_squared * (first_sector + last_sector) + (ux * vy - uy * vx)

    return 0.5 * total


if __name__ == "__main__":
    raise SystemExit("This oracle is imported by static package tooling; no workload runner is bundled.")
