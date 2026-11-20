"""Independent fan-triangulation reference for polygon area centroids."""

from __future__ import annotations

import struct

MIN_VERTICES = 3
MAX_VERTICES = 16
MAX_COORDINATE = 50
MAX_PARSEABLE_INPUT_LENGTH = 34
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
        x = values[1 + 2 * i]
        y = values[2 + 2 * i]
        if not (-MAX_COORDINATE <= x <= MAX_COORDINATE
                and -MAX_COORDINATE <= y <= MAX_COORDINATE):
            return None
        points.append((x, y))
    if len(set(points)) != count:
        return None
    signed_area2 = 0
    for i, point in enumerate(points):
        following = points[(i + 1) % count]
        signed_area2 += point[0] * following[1] - following[0] * point[1]
    if signed_area2 == 0:
        return None
    direction = 1 if signed_area2 > 0 else -1
    for i, point in enumerate(points):
        following = points[(i + 1) % count]
        for j, candidate in enumerate(points):
            if j == i or j == (i + 1) % count:
                continue
            determinant = ((following[0] - point[0]) * (candidate[1] - point[1])
                           - (following[1] - point[1]) * (candidate[0] - point[0]))
            if direction * determinant <= 0:
                return None
    return points, direction


def _quantize(numerator: int, denominator: int) -> int:
    if denominator < 0:
        denominator = -denominator
        numerator = -numerator
    polarity = -1 if numerator < 0 else 1
    quotient, remainder = divmod(abs(numerator) * OUTPUT_SCALE, denominator)
    rounded = quotient + int(2 * remainder >= denominator)
    return polarity * rounded


def expected_output(values, capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    points, direction = parsed

    # The fan from vertex zero partitions this strictly convex region into
    # signed triangles; each triangle's centroid is its vertex average.
    origin = points[0]
    twice_area = 0
    weighted_x = 0
    weighted_y = 0
    for i in range(1, len(points) - 1):
        left, right = points[i], points[i + 1]
        determinant = ((left[0] - origin[0]) * (right[1] - origin[1])
                       - (left[1] - origin[1]) * (right[0] - origin[0]))
        twice_area += determinant
        weighted_x += determinant * (origin[0] + left[0] + right[0])
        weighted_y += determinant * (origin[1] + left[1] + right[1])
    if twice_area == 0 or (1 if twice_area > 0 else -1) != direction:
        return -1, b""
    centroid_x = _quantize(weighted_x, 3 * twice_area)
    centroid_y = _quantize(weighted_y, 3 * twice_area)

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
