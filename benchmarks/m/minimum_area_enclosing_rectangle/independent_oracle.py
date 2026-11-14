"""Unexecuted independent edge-orientation projection scan."""

from fractions import Fraction
import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 7 <= len(values) <= 34
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in values)):
        return -1, b""
    n = values[0]
    if not 3 <= n <= 16 or len(values) != 1+2*n or any(x < -100 or x > 100 for x in values[1:]):
        return -1, b""
    points = tuple(zip(values[1::2], values[2::2]))
    areas = []
    for i, (ax, ay) in enumerate(points):
        bx, by = points[(i+1)%n]
        dx, dy = bx-ax, by-ay
        along, across = [], []
        for j, (x, y) in enumerate(points):
            if j != i and j != (i+1)%n and dx*(y-ay)-dy*(x-ax) <= 0:
                return -1, b""
            along.append(dx*x+dy*y)
            across.append(dx*y-dy*x)
        if dx == 0 and dy == 0:
            return -1, b""
        areas.append(Fraction((max(along)-min(along))*(max(across)-min(across)), dx*dx+dy*dy))
    area = min(areas)
    if output_is_null or capacity is not None and capacity < 16:
        return -2, b""
    return 16, struct.pack("<qq", area.numerator, area.denominator)
