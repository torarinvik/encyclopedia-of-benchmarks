"""Independent linear edge-scan oracle for convex polygon membership."""

from __future__ import annotations

from collections.abc import Sequence

from point_in_convex_polygon_log_query_oracle import (
    MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES,
    _encode,
    _on_segment,
    _parse,
    _subtract,
)


def _ray_scan_contains(polygon: Sequence[tuple[int, int]], query: tuple[int, int]) -> bool:
    qx, qy = query
    inside = False
    for index, first in enumerate(polygon):
        second = polygon[(index + 1) % len(polygon)]
        dx = second[0] - first[0]
        dy = second[1] - first[1]
        side = dx * (qy - first[1]) - dy * (qx - first[0])
        if side == 0 and min(first[0], second[0]) <= qx <= max(first[0], second[0]) \
                and min(first[1], second[1]) <= qy <= max(first[1], second[1]):
            return True
        if (first[1] > qy) != (second[1] > qy):
            if (dy > 0 and side > 0) or (dy < 0 and side < 0):
                inside = not inside
    return inside


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    polygon, queries = parsed
    encoded = _encode([int(_ray_scan_contains(polygon, point)) for point in queries])
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(output_is_null) is not bool or type(effective_capacity) is not int or effective_capacity < 0:
        return -2, b""
    if (output_is_null and encoded) or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded


def verify_output(values: Sequence[int] | None, result: int, output: bytes,
                  capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    return expected_output(values, capacity, output_is_null, input_is_null, input_length) == (result, output)
