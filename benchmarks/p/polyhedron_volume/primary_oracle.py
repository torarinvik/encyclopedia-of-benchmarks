"""Primary determinant-sum reference for oriented triangle-mesh volume."""

from __future__ import annotations

import struct

MIN_FACES = 4
MAX_FACES = 32
MAX_COORDINATE = 50
MAX_VALID_INPUT_LENGTH = 1 + 9 * MAX_FACES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8
OUTPUT_SCALE = 1_000_000


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def _det(a, b, c):
    cross = _cross(b, c)
    return a[0] * cross[0] + a[1] * cross[1] + a[2] * cross[2]


def _parse(values, input_length=None, input_is_null=False):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return None
    face_count = values[0]
    if type(face_count) is not int or not MIN_FACES <= face_count <= MAX_FACES:
        return None
    if input_length != 1 + 9 * face_count:
        return None
    faces = []
    for face in range(face_count):
        vertices = []
        for corner in range(3):
            offset = 1 + 9 * face + 3 * corner
            point = tuple(values[offset:offset + 3])
            if any(abs(coordinate) > MAX_COORDINATE for coordinate in point):
                return None
            vertices.append(point)
        a, b, c = vertices
        if _cross(tuple(b[i] - a[i] for i in range(3)),
                  tuple(c[i] - a[i] for i in range(3))) == (0, 0, 0):
            return None
        faces.append(tuple(vertices))

    directed_edges = []
    for a, b, c in faces:
        directed_edges.extend(((a, b), (b, c), (c, a)))
    for start, end in directed_edges:
        same = sum(1 for a, b in directed_edges if a == start and b == end)
        reverse = sum(1 for a, b in directed_edges if a == end and b == start)
        if same != 1 or reverse != 1:
            return None
    return faces


def _round_ratio_away(numerator, denominator):
    sign = -1 if numerator < 0 else 1
    scaled = abs(numerator) * OUTPUT_SCALE
    quotient, remainder = divmod(scaled, denominator)
    if 2 * remainder >= denominator:
        quotient += 1
    return sign * quotient


def expected_output(values, capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    faces = _parse(values, input_length, input_is_null)
    if faces is None:
        return -1, b""
    determinant_sum = sum(_det(*face) for face in faces)
    result = _round_ratio_away(determinant_sum, 6)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    output = struct.pack("<q", result)
    return len(output), output


def expected_result(values, **kwargs):
    return expected_output(values, **kwargs)[0]
