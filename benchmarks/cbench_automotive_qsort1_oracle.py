"""Independent bounded oracle for cBench automotive_qsort1."""
from __future__ import annotations

import math
import struct

MAX_POINTS = 128
MAX_COORDINATE = 1_000_000
MAX_INPUT_VALUES = 1 + 3 * MAX_POINTS
MAX_OUTPUT_BYTES = 12 * MAX_POINTS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: object) -> list[tuple[int, int, int]] | None:
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_VALUES:
        return None
    if any(not isinstance(v, int) or isinstance(v, bool) for v in values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_POINTS or len(values) != 1 + 3 * count:
        return None
    points = []
    radii = set()
    for i in range(count):
        point = tuple(values[1 + 3 * i:4 + 3 * i])
        if any(not -MAX_COORDINATE <= c <= MAX_COORDINATE for c in point):
            return None
        radius2 = sum(c * c for c in point)
        if radius2 in radii:
            return None
        radii.add(radius2)
        points.append(point)
    return points


def expected_output(values: object) -> tuple[int, bytes] | None:
    """Return (result, bytes); invalid frames return None; output errors return -2."""
    points = _parse(values)
    if points is None:
        return None
    ordered = sorted(points, key=lambda p: math.sqrt(p[0] ** 2 + p[1] ** 2 + p[2] ** 2))
    output = b"".join(struct.pack("<iii", *p) for p in ordered)
    return len(output), output


def expected_result(values: object, output_capacity: int, output_is_null: bool = False) -> tuple[int, bytes]:
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    required = len(parsed) * 12
    if output_is_null or output_capacity < required:
        return OUTPUT_ERROR, b""
    return expected_output(values)  # type: ignore[return-value]
