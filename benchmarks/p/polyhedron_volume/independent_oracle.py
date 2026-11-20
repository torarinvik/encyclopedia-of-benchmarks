"""Divergence-theorem face-integral reference using exact rational arithmetic."""

from __future__ import annotations

import struct

MAX_FACES = 32
MAX_COORDINATE = 50
MAX_PARSEABLE_INPUT_LENGTH = 290
MAX_OUTPUT_BYTES = 8
OUTPUT_SCALE = 1_000_000


def _face_area_vector(a, b, c):
    ab = tuple(b[i] - a[i] for i in range(3))
    ac = tuple(c[i] - a[i] for i in range(3))
    return (ab[1] * ac[2] - ab[2] * ac[1],
            ab[2] * ac[0] - ab[0] * ac[2],
            ab[0] * ac[1] - ab[1] * ac[0])


def _read_mesh(words, length, is_null):
    if is_null or not isinstance(words, (list, tuple)):
        return None
    if length is None:
        length = len(words)
    if (type(length) is not int or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(words)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in words):
        return None
    faces_count = words[0]
    if type(faces_count) is not int or not 4 <= faces_count <= MAX_FACES:
        return None
    if length != 1 + 9 * faces_count:
        return None
    faces = []
    for face_index in range(faces_count):
        flat = words[1 + face_index * 9:1 + (face_index + 1) * 9]
        vertices = tuple(tuple(flat[3 * corner:3 * corner + 3]) for corner in range(3))
        if any(any(abs(value) > MAX_COORDINATE for value in point) for point in vertices):
            return None
        if len(set(vertices)) != 3 or _face_area_vector(*vertices) == (0, 0, 0):
            return None
        faces.append(vertices)

    # Canonical unoriented edge keys make this check independent of the
    # primary's per-edge directed-pair scan.
    edge_counts = {}
    for a, b, c in faces:
        for start, end in ((a, b), (b, c), (c, a)):
            key = (start, end) if start < end else (end, start)
            count, orientation = edge_counts.get(key, (0, 0))
            edge_counts[key] = (count + 1, orientation + (1 if start < end else -1))
    if any(count != 2 or orientation != 0 for count, orientation in edge_counts.values()):
        return None
    return faces


def _round_away(numerator, denominator):
    sign = -1 if numerator < 0 else 1
    scaled = abs(numerator) * OUTPUT_SCALE
    quotient, remainder = divmod(scaled, denominator)
    if 2 * remainder >= denominator:
        quotient += 1
    return sign * quotient


def expected_output(values, capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    faces = _read_mesh(values, input_length, input_is_null)
    if faces is None:
        return -1, b""
    # The divergence theorem gives V = (1/3) sum(face centroid · area vector).
    # The unnormalized triangle area vector is (b-a) × (c-a); the face
    # centroid is (a+b+c)/3, so the exact denominator is 18.
    flux_numerator = 0
    for a, b, c in faces:
        area_vector = _face_area_vector(a, b, c)
        flux_numerator += sum((a[axis] + b[axis] + c[axis]) * area_vector[axis]
                              for axis in range(3))
    result = _round_away(flux_numerator, 18)
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
