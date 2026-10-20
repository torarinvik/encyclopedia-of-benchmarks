"""Independent empty-circumcircle oracle for bounded Delaunay triangulation."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_POINTS = 8
MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_TRIANGLES = 2 * MAX_POINTS - 5
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_TRIANGLES)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _orient(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _incircle(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int], d: tuple[int, int]) -> int:
    ax, ay = a[0] - d[0], a[1] - d[1]
    bx, by = b[0] - d[0], b[1] - d[1]
    cx, cy = c[0] - d[0], c[1] - d[1]
    aa, bb, cc = ax * ax + ay * ay, bx * bx + by * by, cx * cx + cy * cy
    return aa * (bx * cy - by * cx) - bb * (ax * cy - ay * cx) + cc * (ax * by - ay * bx)


def _parse(values: Sequence[int]) -> list[tuple[int, int]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 7 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return None
    count = values[0]
    if not 3 <= count <= MAX_POINTS or len(values) != 1 + 2 * count:
        return None
    points = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(count)]
    if any(not -10 <= coordinate <= 10 for point in points for coordinate in point):
        return None
    if len(set(points)) != count:
        return None
    for a, b, c in itertools.combinations(range(count), 3):
        if _orient(points[a], points[b], points[c]) == 0:
            return None
    for a, b, c, d in itertools.combinations(range(count), 4):
        if _incircle(points[a], points[b], points[c], points[d]) == 0:
            return None

    # Preserve the pinned bbox-derived supertriangle's nonzero-area precondition.
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    dmax = max(max(xs) - min(xs), max(ys) - min(ys))
    midx = (min(xs) + max(xs)) / 2.0
    midy = (min(ys) + max(ys)) / 2.0
    combined = points + [
        (midx - 20 * dmax, midy - dmax),
        (midx, midy + 20 * dmax),
        (midx + 20 * dmax, midy - dmax),
    ]
    for a, b, c in itertools.combinations(range(len(combined)), 3):
        if _orient(combined[a], combined[b], combined[c]) == 0:
            return None
    return points


def _empty_circle_triangles(points: list[tuple[int, int]]) -> list[tuple[int, int, int]]:
    triangles: list[tuple[int, int, int]] = []
    for triple in itertools.combinations(range(len(points)), 3):
        a, b, c = triple
        orientation = _orient(points[a], points[b], points[c])
        if all(
            _incircle(points[a], points[b], points[c], points[d]) * orientation < 0
            for d in range(len(points)) if d not in triple
        ):
            triangles.append(triple)
    return sorted(triangles)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    points = _parse(values)
    if points is None:
        return INVALID_RESULT, b""
    triangles = _empty_circle_triangles(points)
    if not triangles or len(triangles) > MAX_TRIANGLES:
        return INVALID_RESULT, b""
    words = [len(triangles), *(index for triangle in triangles for index in triangle)]
    encoded = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
