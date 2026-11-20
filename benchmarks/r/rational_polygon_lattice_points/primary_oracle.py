"""Exact edge floor-sums for strict lattice points inside a rational polygon."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_SCALE = 8
MAX_COORD = 32
MAX_VALID_LENGTH = 2 + 2 * MAX_N
MAX_PARSEABLE_LENGTH = MAX_VALID_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _floor_div(a: int, b: int) -> int:
    return a // b


def _ceil_div(a: int, b: int) -> int:
    return -((-a) // b)


def _floor_sum(n: int, m: int, a: int, b: int) -> int:
    """Return sum(floor((a*i+b)/m), i=0..n-1), including signed a and b."""
    qa, a = divmod(a, m)
    qb, b = divmod(b, m)
    answer = qa * n * (n - 1) // 2 + qb * n
    while True:
        if a >= m:
            answer += (n - 1) * n * (a // m) // 2
            a %= m
        if b >= m:
            answer += n * (b // m)
            b %= m
        top = a * n + b
        if top < m:
            return answer
        n = top // m
        b = top % m
        m, a = a, m


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[tuple[int, int]], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    scale, n = values[:2]
    if not 2 <= scale <= MAX_SCALE or not 3 <= n <= MAX_N:
        return None
    if len(values) != 2 + 2 * n:
        return None
    points = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(n)]
    if any(abs(x) > MAX_COORD or abs(y) > MAX_COORD
           or abs(x) > 4 * scale or abs(y) > 4 * scale for x, y in points):
        return None
    if len(set(points)) != n:
        return None
    if not any(x % scale != 0 or y % scale != 0 for x, y in points):
        return None
    area2 = sum(points[i][0] * points[(i + 1) % n][1]
                - points[i][1] * points[(i + 1) % n][0] for i in range(n))
    if area2 == 0:
        return None
    orientation = 1 if area2 > 0 else -1
    for i, a in enumerate(points):
        b = points[(i + 1) % n]
        for j, c in enumerate(points):
            if j == i or j == (i + 1) % n:
                continue
            cross = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
            if cross * orientation <= 0:
                return None
    return scale, points, orientation


def _edge_floor_sum(scale: int, a: tuple[int, int], b: tuple[int, int],
                    start: int, stop: int) -> tuple[int, int]:
    """Return floor(line(x)) sum over the half-open integer range [start, stop)."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = stop - start
    if n <= 0:
        return 0, 0
    aa = dy * scale
    bb = a[1] * dx - dy * a[0]
    denominator = scale * dx
    if denominator < 0:
        aa, bb, denominator = -aa, -bb, -denominator
    return _floor_sum(n, denominator, aa, aa * start + bb), n


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
            intersection_num = ax * dy + (py - ay) * dx
            point_num = px * dy
            if ((dy > 0 and intersection_num > point_num)
                    or (dy < 0 and intersection_num < point_num)):
                inside = not inside
    return inside


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    scale, points, orientation = decoded
    signed_count = 0
    event_columns = sorted({x // scale for x, _ in points if x % scale == 0})
    for i, a in enumerate(points):
        b = points[(i + 1) % len(points)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        if dx == 0:
            continue
        start = _ceil_div(min(a[0], b[0]), scale)
        stop = _ceil_div(max(a[0], b[0]), scale)
        cursor = start
        for event_x in event_columns:
            if cursor <= event_x < stop:
                floors, columns = _edge_floor_sum(scale, a, b, cursor, event_x)
                if dx > 0:
                    signed_count -= floors
                else:
                    left, right = min(a[0], b[0]), max(a[0], b[0])
                    aa = dy * scale
                    bb = a[1] * dx - dy * a[0]
                    den = scale * dx
                    if den < 0:
                        aa, bb, den = -aa, -bb, -den
                    base = aa * cursor + bb
                    signed_count += -_floor_sum(columns, den, -aa, -base) - columns
                cursor = event_x + 1
        if cursor < stop:
            floors, columns = _edge_floor_sum(scale, a, b, cursor, stop)
            if dx > 0:
                signed_count -= floors
            else:
                aa = dy * scale
                bb = a[1] * dx - dy * a[0]
                den = scale * dx
                if den < 0:
                    aa, bb, den = -aa, -bb, -den
                base = aa * cursor + bb
                signed_count += -_floor_sum(columns, den, -aa, -base) - columns
    for x in event_columns:
        signed_count += orientation * sum(_strictly_inside(scale, points, x, y)
                                          for y in range(-4, 5))
    result = signed_count * orientation
    return result if result >= 0 else -1
