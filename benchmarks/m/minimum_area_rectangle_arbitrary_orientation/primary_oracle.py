"""Bounded pair-of-diagonals reference for arbitrary-orientation rectangles."""

from __future__ import annotations

from collections.abc import Sequence
MAX_N = 16
MAX_COORD = 32
MAX_VALID_INPUT_LENGTH = 33
MAX_PARSEABLE_INPUT_LENGTH = 34
INVALID_RESULT = -1


def _points(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[tuple[int, int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63)
                   for v in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 4 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return None
    points: list[tuple[int, int]] = []
    for i in range(n):
        x, y = values[1 + 2 * i:3 + 2 * i]
        if not -MAX_COORD <= x <= MAX_COORD or not -MAX_COORD <= y <= MAX_COORD:
            return None
        point = (x, y)
        if point in points:
            return None
        points.append(point)
    return points


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _points(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    best: int | None = None
    for a in range(len(points)):
        for b in range(a + 1, len(points)):
            ax, ay = points[a]
            bx, by = points[b]
            mid_x, mid_y = ax + bx, ay + by
            dx1, dy1 = ax - bx, ay - by
            length1 = dx1 * dx1 + dy1 * dy1
            for c in range(len(points)):
                for d in range(c + 1, len(points)):
                    if c < a or (c == a and d <= b):
                        continue
                    if a == c or a == d or b == c or b == d:
                        continue
                    cx, cy = points[c]
                    dx, dy = points[d]
                    if mid_x != cx + dx or mid_y != cy + dy:
                        continue
                    dx2, dy2 = cx - dx, cy - dy
                    if length1 != dx2 * dx2 + dy2 * dy2:
                        continue
                    doubled_area = abs(dx1 * dy2 - dy1 * dx2)
                    if best is None or doubled_area < best:
                        best = doubled_area
    return 0 if best is None else best
