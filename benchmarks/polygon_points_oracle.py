"""Oracle for the bounded Rust polygon lattice-point routine."""

from __future__ import annotations

import math

MIN_VERTICES = 3
MAX_VERTICES = 32
MIN_COORDINATE = -1000
MAX_COORDINATE = 1000
MAX_INPUT_LENGTH = 66  # admit one trailing value for malformed-input coverage
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES or len(values) != 1 + 2 * n:
        return INVALID_RESULT
    coordinates = values[1:]
    if any(not MIN_COORDINATE <= value <= MAX_COORDINATE for value in coordinates):
        return INVALID_RESULT

    points = [(coordinates[2 * i], coordinates[2 * i + 1]) for i in range(n)]
    origin_x, origin_y = points[0]
    doubled_area = 0
    for i in range(2, n):
        x1 = points[i][0] - origin_x
        y1 = points[i][1] - origin_y
        x2 = points[i - 1][0] - origin_x
        y2 = points[i - 1][1] - origin_y
        doubled_area += x1 * y2 - x2 * y1
    area = abs(doubled_area) // 2

    boundary = n
    for i in range(n):
        x1, y1 = points[i]
        x2, y2 = points[(i + 1) % n]
        boundary += abs(math.gcd(x1 - x2, y1 - y2)) - 1
    return area + 1 - boundary // 2
