"""Exact vertical-stripe reference for the bounded triangle-union profile."""

from __future__ import annotations

import struct
from fractions import Fraction
from math import gcd

MAX_TRIANGLES = 3
MAX_INPUT_LENGTH = 1 + 6 * MAX_TRIANGLES
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16
MAX_WORKSPACE_BYTES = 8192
COORD_MIN = -1
COORD_MAX = 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_AREA_DENOMINATOR = 2_822_400
MAX_AREA_NUMERATOR = 11_289_600


def _cross(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _decode(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_TRIANGLES or len(values) != 1 + 6 * n:
        return None
    triangles = []
    for t in range(n):
        raw = values[1 + 6*t: 7 + 6*t]
        if any(not COORD_MIN <= v <= COORD_MAX for v in raw):
            return None
        points = tuple((raw[2*i], raw[2*i+1]) for i in range(3))
        if len(set(points)) != 3 or _cross(*points) == 0:
            return None
        triangles.append(points)
    return triangles


def _segments(triangles):
    return [(a, b, 3*t+i) for t, tri in enumerate(triangles)
            for i, (a, b) in enumerate(zip(tri, tri[1:] + tri[:1]))]


def _on_segment(p, a, b):
    return (min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _intersection_x(a, b, c, d):
    rx, ry = b[0]-a[0], b[1]-a[1]
    sx, sy = d[0]-c[0], d[1]-c[1]
    den = rx*sy - ry*sx
    if den == 0:
        return None
    qx, qy = c[0]-a[0], c[1]-a[1]
    t = Fraction(qx*sy - qy*sx, den)
    u = Fraction(qx*ry - qy*rx, den)
    if not 0 <= t <= 1 or not 0 <= u <= 1:
        return None
    return Fraction(a[0]) + t*rx


def _y_at(segment, x):
    a, b, _ = segment
    if a[0] == b[0]:
        raise ValueError("vertical segment has no stripe crossing function")
    return Fraction(a[1]) + Fraction(b[1]-a[1], b[0]-a[0]) * (x-a[0])


def _vertical_area(triangles):
    segs = _segments(triangles)
    events = {Fraction(p[0]) for tri in triangles for p in tri}
    for i, (a, b, _) in enumerate(segs):
        for c, d, _ in segs[i+1:]:
            x = _intersection_x(a, b, c, d)
            if x is not None:
                events.add(x)
    xs = sorted(events)
    area = Fraction(0)
    for xl, xr in zip(xs, xs[1:]):
        if xl == xr:
            continue
        xm = (xl+xr)/2
        intervals = []
        for ti in range(len(triangles)):
            crossing = []
            for seg in segs[3*ti:3*ti+3]:
                a, b, sid = seg
                if a[0] != b[0] and min(a[0], b[0]) < xm < max(a[0], b[0]):
                    crossing.append((_y_at(seg, xm), sid, seg))
            if not crossing:
                continue
            crossing.sort(key=lambda item: (item[0], item[1]))
            if len(crossing) != 2:
                raise AssertionError("open stripe must meet a triangle in two sides")
            intervals.append((crossing[0][0], crossing[1][0],
                              crossing[0][2], crossing[1][2],
                              crossing[0][1], crossing[1][1]))
        intervals.sort(key=lambda z: (z[0], z[4], z[1], z[5]))
        merged = []
        for lo, hi, lo_seg, hi_seg, lo_id, hi_id in intervals:
            if not merged or lo > merged[-1][1]:
                merged.append([lo, hi, lo_seg, hi_seg, lo_id, hi_id])
            elif hi > merged[-1][1] or (hi == merged[-1][1] and hi_id < merged[-1][5]):
                merged[-1][1] = hi
                merged[-1][3] = hi_seg
                merged[-1][5] = hi_id
        for _lo, _hi, low_seg, high_seg, _li, _hiid in merged:
            left_h = _y_at(high_seg, xl) - _y_at(low_seg, xl)
            right_h = _y_at(high_seg, xr) - _y_at(low_seg, xr)
            area += (xr-xl) * (left_h+right_h) / 2
    return area


def _payload(area: Fraction) -> bytes:
    if area < 0:
        raise AssertionError("union area cannot be negative")
    return struct.pack("<qq", area.numerator, area.denominator)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    triangles = _decode(values, input_length, input_is_null)
    if triangles is None:
        return INVALID_RESULT, b""
    payload = _payload(_vertical_area(triangles))
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload

