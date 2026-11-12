"""Independent exact threshold oracle for distinct common tangent lines."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COORDINATE = 100_000
MAX_RADIUS = 100_000
MAX_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != 6:
        return -1
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return -1
    x1, y1, radius1, x2, y2, radius2 = values
    if max(abs(x1), abs(y1), abs(x2), abs(y2)) > MAX_COORDINATE:
        return -1
    if radius1 < 0 or radius1 > MAX_RADIUS or radius2 < 0 or radius2 > MAX_RADIUS:
        return -1
    distance_squared = (x2 - x1) ** 2 + (y2 - y1) ** 2
    if distance_squared == 0:
        return -1

    if radius1 == 0 and radius2 == 0:
        return 1
    if radius1 == 0 or radius2 == 0:
        positive_radius = max(radius1, radius2)
        boundary_squared = positive_radius * positive_radius
        if distance_squared > boundary_squared:
            return 2
        if distance_squared == boundary_squared:
            return 1
        return 0

    inner_threshold = abs(radius1 - radius2) ** 2
    outer_threshold = (radius1 + radius2) ** 2
    if distance_squared > outer_threshold:
        return 4
    if distance_squared == outer_threshold:
        return 3
    if distance_squared > inner_threshold:
        return 2
    if distance_squared == inner_threshold:
        return 1
    return 0
