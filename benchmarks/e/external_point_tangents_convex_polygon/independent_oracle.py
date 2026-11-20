"""Independent direct-support-line reference for polygon point tangents."""

from __future__ import annotations

import struct

try:
    from .primary_oracle import (
        MAX_COORDINATE,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_QUERIES,
        MAX_VERTICES,
        WORKSPACE_BYTES,
        cross,
        sub,
        valid_polygon,
        valid_query,
    )
except ImportError:
    from primary_oracle import (
        MAX_COORDINATE,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_QUERIES,
        MAX_VERTICES,
        WORKSPACE_BYTES,
        cross,
        sub,
        valid_polygon,
        valid_query,
    )


def scan_tangents(poly: list[tuple[int, int]], q: tuple[int, int]) -> tuple[int, int] | None:
    left = []
    right = []
    for i, point in enumerate(poly):
        here = sub(point, q)
        prev_point = sub(poly[(i - 1) % len(poly)], q)
        next_point = sub(poly[(i + 1) % len(poly)], q)
        prev_side = cross(here, prev_point)
        next_side = cross(here, next_point)
        if prev_side < 0 and next_side < 0:
            left.append(i)
        if prev_side > 0 and next_side > 0:
            right.append(i)
    if len(left) != 1 or len(right) != 1 or left[0] == right[0]:
        return None
    return tuple(sorted((left[0], right[0])))


def expected_output(values: list[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or values is None:
        return -1, b""
    length = len(values) if input_length is None else input_length
    if length != len(values) or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if any(not isinstance(x, int) or x < -(1 << 63) or x >= (1 << 63) for x in values):
        return -1, b""
    n, q_count = values[0], values[1]
    if not (3 <= n <= MAX_VERTICES and 0 <= q_count <= MAX_QUERIES):
        return -1, b""
    if length != 2 + 2 * n + 2 * q_count:
        return -1, b""
    at = 2
    polygon = []
    for _ in range(n):
        x, y = values[at], values[at + 1]
        at += 2
        if not (-MAX_COORDINATE <= x <= MAX_COORDINATE and -MAX_COORDINATE <= y <= MAX_COORDINATE):
            return -1, b""
        polygon.append((x, y))
    if not valid_polygon(polygon):
        return -1, b""
    output_ids = []
    for _ in range(q_count):
        x, y = values[at], values[at + 1]
        at += 2
        if not (-MAX_COORDINATE <= x <= MAX_COORDINATE and -MAX_COORDINATE <= y <= MAX_COORDINATE):
            return -1, b""
        query = (x, y)
        if not valid_query(polygon, query):
            return -1, b""
        pair = scan_tangents(polygon, query)
        if pair is None:
            return -1, b""
        output_ids.extend(pair)

    needed = 8 * len(output_ids)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < needed or output_is_null):
        return -2, b""
    return needed, b"".join(struct.pack("<q", value) for value in output_ids)
