"""Primary exact shoelace-centroid reference for bounded convex polygons."""

from __future__ import annotations

import struct

MIN_VERTICES = 3
MAX_VERTICES = 16
MAX_COORDINATE = 50
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16
OUTPUT_SCALE = 1_000_000


def _parse(values, input_length=None, input_is_null=False):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    count = values[0]
    if type(count) is not int or not MIN_VERTICES <= count <= MAX_VERTICES:
        return None
    if input_length != 1 + 2 * count:
        return None

    points = []
    for i in range(count):
        x, y = values[1 + 2 * i:3 + 2 * i]
        if not (-MAX_COORDINATE <= x <= MAX_COORDINATE
                and -MAX_COORDINATE <= y <= MAX_COORDINATE):
            return None
        points.append((x, y))
    if len(set(points)) != count:
        return None

    twice_area = sum(
        points[i][0] * points[(i + 1) % count][1]
        - points[(i + 1) % count][0] * points[i][1]
        for i in range(count)
    )
    if twice_area == 0:
        return None
    orientation = 1 if twice_area > 0 else -1
    for i, (x0, y0) in enumerate(points):
        x1, y1 = points[(i + 1) % count]
        for j, (x, y) in enumerate(points):
            if j == i or j == (i + 1) % count:
                continue
            side = (x1 - x0) * (y - y0) - (y1 - y0) * (x - x0)
            if side * orientation <= 0:
                return None
    return points, twice_area


def _round_ratio_micro(numerator: int, denominator: int) -> int:
    if denominator < 0:
        numerator = -numerator
        denominator = -denominator
    sign = -1 if numerator < 0 else 1
    scaled = abs(numerator) * OUTPUT_SCALE
    quotient, remainder = divmod(scaled, denominator)
    if 2 * remainder >= denominator:
        quotient += 1
    return sign * quotient


def expected_output(values, capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    points, twice_area = parsed
    count = len(points)
    numerator_x = 0
    numerator_y = 0
    for i, (x0, y0) in enumerate(points):
        x1, y1 = points[(i + 1) % count]
        cross = x0 * y1 - x1 * y0
        numerator_x += (x0 + x1) * cross
        numerator_y += (y0 + y1) * cross
    denominator = 3 * twice_area
    centroid_x = _round_ratio_micro(numerator_x, denominator)
    centroid_y = _round_ratio_micro(numerator_y, denominator)

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    output = struct.pack("<qq", centroid_x, centroid_y)
    return len(output), output


def expected_result(values, **kwargs):
    return expected_output(values, **kwargs)[0]
