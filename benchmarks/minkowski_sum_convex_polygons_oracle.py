"""Primary edge-merge oracle for bounded convex-polygon Minkowski sums."""

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


def _cross(a: Point, b: Point) -> int:
    return a[0] * b[1] - a[1] * b[0]


def _edge(polygon: Sequence[Point], index: int) -> Point:
    first = polygon[index]
    second = polygon[(index + 1) % len(polygon)]
    return second[0] - first[0], second[1] - first[1]


def _half(vector: Point) -> int:
    return 0 if vector[1] > 0 or (vector[1] == 0 and vector[0] >= 0) else 1


def _angle_compare(first: Point, second: Point) -> int:
    first_half, second_half = _half(first), _half(second)
    if first_half != second_half:
        return -1 if first_half < second_half else 1
    turn = _cross(first, second)
    return -1 if turn > 0 else (1 if turn < 0 else 0)


def _is_strict_ccw(polygon: Sequence[Point]) -> bool:
    wraps = 0
    for index in range(len(polygon)):
        first = _edge(polygon, index)
        second = _edge(polygon, (index + 1) % len(polygon))
        if first == (0, 0) or _cross(first, second) <= 0:
            return False
        if _angle_compare(second, first) < 0:
            wraps += 1
    return wraps == 1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[Point], list[Point]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 14 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m = values[:2]
    if not 3 <= n <= MAX_VERTICES or not 3 <= m <= MAX_VERTICES:
        return None
    if len(values) != 2 + 2 * n + 2 * m:
        return None
    cursor = 2
    polygons: list[list[Point]] = []
    for count in (n, m):
        points: list[Point] = []
        for _ in range(count):
            x, y = values[cursor:cursor + 2]
            cursor += 2
            if abs(x) > MAX_COORDINATE or abs(y) > MAX_COORDINATE:
                return None
            points.append((x, y))
        if not _is_strict_ccw(points):
            return None
        polygons.append(points)
    return polygons[0], polygons[1]


def _lowest_rotation(polygon: list[Point]) -> list[Point]:
    first = min(range(len(polygon)), key=lambda index: (polygon[index][1], polygon[index][0]))
    return polygon[first:] + polygon[:first]


def _merged_boundary(first: list[Point], second: list[Point]) -> list[Point]:
    p = _lowest_rotation(first)
    q = _lowest_rotation(second)
    i = j = 0
    result: list[Point] = []
    while i < len(p) or j < len(q):
        result.append((p[i % len(p)][0] + q[j % len(q)][0],
                       p[i % len(p)][1] + q[j % len(q)][1]))
        if i == len(p):
            j += 1
            continue
        if j == len(q):
            i += 1
            continue
        order = _angle_compare(_edge(p, i), _edge(q, j))
        if order <= 0:
            i += 1
        if order >= 0:
            j += 1
    return result


def _encode(points: Sequence[Point]) -> bytes:
    words = [len(points)]
    for x, y in points:
        words.extend((x, y))
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    polygons = _parse(values, input_length, input_is_null)
    if polygons is None:
        return -1, b""
    encoded = _encode(_merged_boundary(*polygons))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded
