"""Independent exact inclusion-exclusion and convex clipping reference."""

from __future__ import annotations

import struct
from fractions import Fraction
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_TRIANGLES = 3
MAX_PARSEABLE_INPUT_LENGTH = 20
COORD_MIN = -1
COORD_MAX = 1


def _cross(a, b, c):
    return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])


def _decode(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_TRIANGLES or len(values) != 1 + 6*n:
        return None
    result = []
    for i in range(n):
        raw = values[1+6*i:7+6*i]
        if any(v < COORD_MIN or v > COORD_MAX for v in raw):
            return None
        tri = tuple((raw[2*j], raw[2*j+1]) for j in range(3))
        if len(set(tri)) != 3 or _cross(*tri) == 0:
            return None
        if _cross(*tri) < 0:
            tri = (tri[0], tri[2], tri[1])
        result.append(tuple((Fraction(x), Fraction(y)) for x, y in tri))
    return result


def _orient(a, b, p):
    return (b[0]-a[0])*(p[1]-a[1]) - (b[1]-a[1])*(p[0]-a[0])


def _line_crossing(p, q, a, b):
    # Intersect segment p--q with the infinite clipping line a--b.
    fp, fq = _orient(a, b, p), _orient(a, b, q)
    t = fp / (fp-fq)
    return (p[0] + t*(q[0]-p[0]), p[1] + t*(q[1]-p[1]))


def _clip(subject, triangle):
    polygon = list(subject)
    for a, b in zip(triangle, triangle[1:] + triangle[:1]):
        if not polygon:
            break
        output = []
        previous = polygon[-1]
        prev_inside = _orient(a, b, previous) >= 0
        for current in polygon:
            cur_inside = _orient(a, b, current) >= 0
            if cur_inside != prev_inside:
                output.append(_line_crossing(previous, current, a, b))
            if cur_inside:
                output.append(current)
            previous, prev_inside = current, cur_inside
        polygon = output
    return polygon


def _area(polygon):
    if len(polygon) < 3:
        return Fraction(0)
    twice = sum(p[0]*q[1]-p[1]*q[0]
                for p, q in zip(polygon, polygon[1:] + polygon[:1]))
    return abs(twice) / 2


def _union_area(triangles):
    total = sum((_area([tuple(map(Fraction, p)) for p in tri]) for tri in triangles), Fraction(0))
    if len(triangles) >= 2:
        for i in range(len(triangles)):
            for j in range(i+1, len(triangles)):
                total -= _area(_clip(triangles[i], triangles[j]))
    if len(triangles) == 3:
        total += _area(_clip(_clip(triangles[0], triangles[1]), triangles[2]))
    return total


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    triangles = _decode(values, input_length, input_is_null)
    if triangles is None:
        return INVALID_RESULT, b""
    area = _union_area(triangles)
    payload = struct.pack("<qq", area.numerator, area.denominator)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 16)):
        return OUTPUT_ERROR, b""
    return 16, payload
