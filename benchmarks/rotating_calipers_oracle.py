"""Independent bounded all-pairs oracle for planar point-set diameter."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300


def rotating_calipers(values: list[int]) -> float:
    if (not values or type(values[0]) is not int
            or not 2 <= values[0] <= 1_024
            or len(values) != 1 + 2 * values[0]
            or any(type(value) is not int or not -1_000_000_000 <= value <= 1_000_000_000
                   for value in values[1:])):
        return INVALID_RESULT
    points = [(values[index], values[index + 1]) for index in range(1, len(values), 2)]
    maximum_squared_distance = 0
    for index, (x1, y1) in enumerate(points):
        for x2, y2 in points[index + 1:]:
            dx, dy = x1 - x2, y1 - y2
            maximum_squared_distance = max(maximum_squared_distance, dx * dx + dy * dy)
    return math.sqrt(maximum_squared_distance)
