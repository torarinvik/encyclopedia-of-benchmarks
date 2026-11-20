"""Independent edge-scan reference for the directed line intersection pair."""

from __future__ import annotations

from fractions import Fraction
import struct

MAX_VERTICES = 16
MAX_COORDINATE = 50
MAX_PARSEABLE_INPUT_LENGTH = 38
MAX_OUTPUT_BYTES = 16


def _input(values, input_length, input_is_null):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    count = values[0]
    if type(count) is not int or not 3 <= count <= MAX_VERTICES:
        return None
    if input_length != 5 + 2 * count:
        return None
    x1, y1, x2, y2 = values[1:5]
    if any(abs(x) > MAX_COORDINATE for x in (x1, y1, x2, y2)):
        return None
    dx, dy = x2 - x1, y2 - y1
    if dx == dy == 0:
        return None
    points = []
    for j in range(count):
        x, y = values[5 + 2 * j:7 + 2 * j]
        if abs(x) > MAX_COORDINATE or abs(y) > MAX_COORDINATE:
            return None
        points.append((x, y))
    if len(set(points)) != count:
        return None
    twice_area = sum(
        points[j][0] * points[(j + 1) % count][1]
        - points[(j + 1) % count][0] * points[j][1]
        for j in range(count)
    )
    if twice_area <= 0:
        return None
    for j, point in enumerate(points):
        following = points[(j + 1) % count]
        for other_index, other in enumerate(points):
            if other_index in (j, (j + 1) % count):
                continue
            turn = ((following[0] - point[0]) * (other[1] - point[1])
                    - (following[1] - point[1]) * (other[0] - point[0]))
            if turn <= 0:
                return None
    return points, (x1, y1), (dx, dy)


def expected_output(values, capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    parsed = _input(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    points, origin, direction = parsed
    dx, dy = direction

    def side(point):
        return dx * (point[1] - origin[1]) - dy * (point[0] - origin[0])

    hits = []
    count = len(points)
    for edge in range(count):
        start = points[edge]
        end = points[(edge + 1) % count]
        first_side, second_side = side(start), side(end)
        if first_side == 0 and second_side == 0:
            pair = (edge, edge)
            break
        if first_side == 0:
            parameter = ((start[0] - origin[0]) * dx
                         + (start[1] - origin[1]) * dy)
            hits.append((Fraction(parameter), edge))
        elif first_side * second_side < 0:
            fraction = Fraction(first_side, first_side - second_side)
            parameter_at_start = ((start[0] - origin[0]) * dx
                                  + (start[1] - origin[1]) * dy)
            along_edge = ((end[0] - start[0]) * dx
                          + (end[1] - start[1]) * dy)
            hits.append((Fraction(parameter_at_start) + fraction * along_edge, edge))
    else:
        if not hits:
            pair = (-1, -1)
        elif len(hits) == 1:
            pair = (hits[0][1], -1)
        elif len(hits) == 2:
            hits.sort(key=lambda hit: hit[0])
            pair = (hits[0][1], hits[1][1])
        else:
            return -1, b""

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    output = struct.pack("<qq", *pair)
    return len(output), output


def expected_result(values, **kwargs):
    return expected_output(values, **kwargs)[0]
