"""Primary logarithmic fan-search oracle for convex polygon membership."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 32
MAX_QUERIES = 32
MAX_INPUT_LENGTH = 131
MAX_OUTPUT_BYTES = 256
WORKSPACE_BYTES = 8192
MAX_COORDINATE = 1_000_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

Point = tuple[int, int]


def _cross(a: Point, b: Point) -> int:
    return a[0] * b[1] - a[1] * b[0]


def _subtract(a: Point, b: Point) -> Point:
    return a[0] - b[0], a[1] - b[1]


def _on_segment(a: Point, b: Point, p: Point) -> bool:
    return (_cross(_subtract(b, a), _subtract(p, a)) == 0
            and min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[Point], list[Point]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, q = values[:2]
    if not 3 <= n <= MAX_VERTICES or not 0 <= q <= MAX_QUERIES:
        return None
    if len(values) != 2 + 2 * n + 2 * q:
        return None
    cursor = 2
    polygon: list[Point] = []
    for _ in range(n):
        x, y = values[cursor:cursor + 2]
        cursor += 2
        if abs(x) > MAX_COORDINATE or abs(y) > MAX_COORDINATE:
            return None
        polygon.append((x, y))
    if len(set(polygon)) != n:
        return None
    # Every other vertex must lie strictly to the left of every directed edge.
    # This enforces strict convexity and CCW orientation without assuming a start vertex.
    for i, a in enumerate(polygon):
        b = polygon[(i + 1) % n]
        edge = _subtract(b, a)
        if edge == (0, 0):
            return None
        for j, point in enumerate(polygon):
            if j != i and j != (i + 1) % n and _cross(edge, _subtract(point, a)) <= 0:
                return None
    queries: list[Point] = []
    for _ in range(q):
        x, y = values[cursor:cursor + 2]
        cursor += 2
        if abs(x) > MAX_COORDINATE or abs(y) > MAX_COORDINATE:
            return None
        queries.append((x, y))
    return polygon, queries


def _fan_contains(polygon: Sequence[Point], query: Point) -> bool:
    pivot_index = min(range(len(polygon)), key=lambda i: (polygon[i][0], polygon[i][1]))
    pivot = polygon[pivot_index]
    fan = [_subtract(polygon[(pivot_index + i) % len(polygon)], pivot)
           for i in range(1, len(polygon))]
    relative = _subtract(query, pivot)
    first_side = _cross(fan[0], relative)
    last_side = _cross(fan[-1], relative)
    if first_side < 0 or last_side > 0:
        return False
    if first_side == 0:
        return _on_segment((0, 0), fan[0], relative)
    if last_side == 0:
        return _on_segment((0, 0), fan[-1], relative)

    lo, hi = 0, len(fan)
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if _cross(fan[mid], relative) >= 0:
            lo = mid
        else:
            hi = mid
    left, right = fan[lo], fan[lo + 1]
    side = _cross(_subtract(right, left), _subtract(relative, left))
    if side < 0:
        return False
    if side == 0:
        return _on_segment(left, right, relative)
    return True


def _encode(answers: Sequence[int]) -> bytes:
    return b"".join(struct.pack("<q", answer) for answer in answers)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    polygon, queries = parsed
    encoded = _encode([int(_fan_contains(polygon, point)) for point in queries])
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(output_is_null) is not bool or type(effective_capacity) is not int or effective_capacity < 0:
        return -2, b""
    if (output_is_null and encoded) or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded
