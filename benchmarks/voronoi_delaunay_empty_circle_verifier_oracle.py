"""Independent verifier using exact rational circumcenters."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT = 17


def _center(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> tuple[Fraction, Fraction]:
    ax, ay = a
    bx, by = b
    cx, cy = c
    denominator = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    sa, sb, sc = ax * ax + ay * ay, bx * bx + by * by, cx * cx + cy * cy
    ux = Fraction(sa * (by - cy) + sb * (cy - ay) + sc * (ay - by), denominator)
    uy = Fraction(sa * (cx - bx) + sb * (ax - cx) + sc * (bx - ax), denominator)
    return ux, uy


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 7 or len(values) > MAX_INPUT or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return -1, b""
    count = values[0]
    if not 3 <= count <= 8 or len(values) != 1 + 2 * count:
        return -1, b""
    pts = [tuple(values[1 + 2 * i:3 + 2 * i]) for i in range(count)]
    if any(not (-50 <= x <= 50 and -50 <= y <= 50) for x, y in pts) or len(set(pts)) != count:
        return -1, b""
    for i in range(count):
        for j in range(i + 1, count):
            for k in range(j + 1, count):
                if (pts[j][0] - pts[i][0]) * (pts[k][1] - pts[i][1]) == (pts[j][1] - pts[i][1]) * (pts[k][0] - pts[i][0]):
                    return -1, b""
    circles = []
    for i in range(count):
        for j in range(i + 1, count):
            for k in range(j + 1, count):
                center = _center(pts[i], pts[j], pts[k])
                radius2 = (center[0] - pts[i][0]) ** 2 + (center[1] - pts[i][1]) ** 2
                circles.append((i, j, k, center, radius2))
    for pos, (i, j, k, center, radius2) in enumerate(circles):
        for a, b, c, other_center, other_radius2 in circles[pos + 1:]:
            if len({i, j, k, a, b, c}) == 4 and center == other_center and radius2 == other_radius2:
                return -1
    edges: set[tuple[int, int]] = set()
    for i, j, k, center, radius2 in circles:
        empty = True
        for d, point in enumerate(pts):
            if d in (i, j, k):
                continue
            distance2 = (center[0] - point[0]) ** 2 + (center[1] - point[1]) ** 2
            if distance2 <= radius2:
                empty = False
                break
        if empty:
            edges.update(((i, j), (i, k), (j, k)))
    fields = [len(edges)]
    for edge in sorted(edges):
        fields.extend(edge)
    payload = b"".join(struct.pack("<q", value) for value in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
