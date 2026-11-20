"""Independent bounded-box enumeration oracle for rational polygons."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_SCALE = 8
MAX_COORD = 32
MAX_PARSEABLE_LENGTH = 19
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _ceil_div(a: int, b: int) -> int:
    return -((-a) // b)


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    scale, n = values[:2]
    if not 2 <= scale <= MAX_SCALE or not 3 <= n <= MAX_N or len(values) != 2 + 2 * n:
        return None
    points = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(n)]
    if any(abs(x) > MAX_COORD or abs(y) > MAX_COORD
           or abs(x) > 4 * scale or abs(y) > 4 * scale for x, y in points):
        return None
    if len(set(points)) != n or not any(x % scale or y % scale for x, y in points):
        return None
    area2 = sum(points[i][0] * points[(i + 1) % n][1]
                - points[i][1] * points[(i + 1) % n][0] for i in range(n))
    if area2 == 0:
        return None
    direction = 1 if area2 > 0 else -1
    for i, a in enumerate(points):
        b = points[(i + 1) % n]
        for j, c in enumerate(points):
            if j == i or j == (i + 1) % n:
                continue
            cross = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
            if cross * direction <= 0:
                return None
    return scale, points


def _strictly_inside(scale: int, points: list[tuple[int, int]], x: int, y: int) -> bool:
    px, py = x * scale, y * scale
    inside = False
    for i, (ax, ay) in enumerate(points):
        bx, by = points[(i + 1) % len(points)]
        cross = (bx - ax) * (py - ay) - (by - ay) * (px - ax)
        if (cross == 0 and min(ax, bx) <= px <= max(ax, bx)
                and min(ay, by) <= py <= max(ay, by)):
            return False
        if (ay > py) != (by > py):
            dy, dx = by - ay, bx - ax
            intersection_numerator = ax * dy + (py - ay) * dx
            point_numerator = px * dy
            if ((dy > 0 and intersection_numerator > point_numerator)
                    or (dy < 0 and intersection_numerator < point_numerator)):
                inside = not inside
    return inside


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    scale, points = decoded
    min_x = _ceil_div(min(x for x, _ in points), scale)
    max_x = max(x for x, _ in points) // scale
    min_y = _ceil_div(min(y for _, y in points), scale)
    max_y = max(y for _, y in points) // scale
    return sum(_strictly_inside(scale, points, x, y)
               for x in range(min_x, max_x + 1)
               for y in range(min_y, max_y + 1))
