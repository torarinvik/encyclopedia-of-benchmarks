"""Independent pair-sum and monotone-hull verifier for convex Minkowski sums."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 32
MAX_INPUT_LENGTH = 131
MAX_COORDINATE = 1_000_000
MAX_OUTPUT_BYTES = 8 * (1 + 4 * MAX_VERTICES)
WORKSPACE_BYTES = 4096
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
Point = tuple[int, int]


def _turn(a: Point, b: Point, c: Point) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _valid(polygon: Sequence[Point]) -> bool:
    if len(polygon) < 3:
        return False
    hull = _monotone_hull(polygon)
    if len(hull) != len(polygon):
        return False
    first = min(range(len(polygon)), key=lambda i: (polygon[i][1], polygon[i][0]))
    return [polygon[(first + i) % len(polygon)] for i in range(len(polygon))] == hull


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[Point], list[Point]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 14 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    p_count, q_count = values[0], values[1]
    if not 3 <= p_count <= MAX_VERTICES or not 3 <= q_count <= MAX_VERTICES:
        return None
    if len(values) != 2 + 2 * p_count + 2 * q_count:
        return None
    cursor = 2
    decoded: list[list[Point]] = []
    for count in (p_count, q_count):
        vertices = []
        for _ in range(count):
            point = (values[cursor], values[cursor + 1])
            cursor += 2
            if any(abs(coord) > MAX_COORDINATE for coord in point):
                return None
            vertices.append(point)
        if not _valid(vertices):
            return None
        decoded.append(vertices)
    return decoded[0], decoded[1]


def _monotone_hull(points: Sequence[Point]) -> list[Point]:
    ordered = sorted(set(points))
    lower: list[Point] = []
    for point in ordered:
        while len(lower) >= 2 and _turn(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper: list[Point] = []
    for point in reversed(ordered):
        while len(upper) >= 2 and _turn(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    hull = lower[:-1] + upper[:-1]
    first = min(range(len(hull)), key=lambda i: (hull[i][1], hull[i][0]))
    return hull[first:] + hull[:first]


def _direct_sum_hull(p: Sequence[Point], q: Sequence[Point]) -> list[Point]:
    return _monotone_hull([(px + qx, py + qy) for px, py in p for qx, qy in q])


def _encode(points: Sequence[Point]) -> bytes:
    words = [len(points)]
    for x, y in points:
        words.extend((x, y))
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    polygons = _decode(values, input_length, input_is_null)
    if polygons is None:
        return -1, b""
    encoded = _encode(_direct_sum_hull(*polygons))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded


def verify_output(values: Sequence[int] | None, result: int, output: bytes,
                 capacity: int | None = None, output_is_null: bool = False,
                 input_is_null: bool = False,
                 input_length: int | None = None) -> bool:
    expected_result, expected_bytes = expected_output(
        values, capacity, output_is_null, input_is_null, input_length)
    return type(result) is int and result == expected_result and output == expected_bytes
