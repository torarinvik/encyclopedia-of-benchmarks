"""Independent one-step Delaunay mesh refinement byte-output oracle."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 7
MAX_PARSEABLE_INPUT_LENGTH = 7
MAX_OUTPUT_BYTES = 152
INVALID_RESULT = -1
OUTPUT_ERROR = -2
COORDINATE_SCALE = 1_000_000
MIN_ANGLE_RADIANS = math.pi / 9.0


def _orient(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _round_ratio_away_from_zero(numerator: int, denominator: int) -> int:
    sign = -1 if numerator < 0 else 1
    quotient, remainder = divmod(abs(numerator), denominator)
    if 2 * remainder >= denominator:
        quotient += 1
    return sign * quotient


def _center_micro(points: list[tuple[int, int]]) -> tuple[int, int]:
    a, b, c = points
    bax, bay = b[0] - a[0], b[1] - a[1]
    cax, cay = c[0] - a[0], c[1] - a[1]
    denominator = 2 * (bax * cay - bay * cax)
    balen_sq = bax * bax + bay * bay
    calen_sq = cax * cax + cay * cay
    x_numerator = a[0] * denominator + cay * balen_sq - bay * calen_sq
    y_numerator = a[1] * denominator + bax * calen_sq - cax * balen_sq
    return (
        _round_ratio_away_from_zero(x_numerator * COORDINATE_SCALE, denominator),
        _round_ratio_away_from_zero(y_numerator * COORDINATE_SCALE, denominator),
    )


def _is_acute(points: list[tuple[int, int]]) -> bool:
    for i in range(3):
        p = points[i]
        u = (points[(i + 1) % 3][0] - p[0], points[(i + 1) % 3][1] - p[1])
        v = (points[(i + 2) % 3][0] - p[0], points[(i + 2) % 3][1] - p[1])
        if u[0] * v[0] + u[1] * v[1] <= 0:
            return False
    return True


def _needs_refinement(points: list[tuple[int, int]]) -> bool:
    lengths = [
        math.hypot(points[1][0] - points[0][0], points[1][1] - points[0][1]),
        math.hypot(points[2][0] - points[1][0], points[2][1] - points[1][1]),
        math.hypot(points[0][0] - points[2][0], points[0][1] - points[2][1]),
    ]
    shortest = min(lengths)
    area2 = _orient(points[0], points[1], points[2])
    radius_edge_ratio = math.prod(lengths) / (2.0 * area2 * shortest)
    beta = 1.0 / (2.0 * math.sin(MIN_ANGLE_RADIANS))
    return radius_edge_ratio > beta * (1.0 + 1e-12)


def _pack_words(words: list[int]) -> bytes:
    return b"".join(struct.pack("<q", word) for word in words)


def _parse(values: Sequence[int] | None, input_is_null: bool, input_length: int | None) -> list[tuple[int, int]] | None:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != MAX_INPUT_LENGTH or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if values[0] != 3:
        return None
    points = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(3)]
    if any(not -100 <= coordinate <= 100 for point in points for coordinate in point):
        return None
    if len(set(points)) != 3 or _orient(*points) <= 0 or not _is_acute(points):
        return None
    return points


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the one-step mesh and quantized coordinates as little-endian i64 words."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT, b""

    scaled_points = [(x * COORDINATE_SCALE, y * COORDINATE_SCALE) for x, y in points]
    if _needs_refinement(points):
        scaled_points.append(_center_micro(points))
        triangles = [(0, 1, 3), (1, 2, 3), (2, 0, 3)]
    else:
        triangles = [(0, 1, 2)]
    words = [len(scaled_points)]
    for x, y in scaled_points:
        words.extend((x, y))
    words.append(len(triangles))
    for triangle in triangles:
        words.extend(triangle)
    encoded = _pack_words(words)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
