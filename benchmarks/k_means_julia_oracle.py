"""Oracle for the deterministic Julia k-means source variant."""

from __future__ import annotations

import math

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_POINTS = 3
MAX_POINTS = 8
MIN_COORDINATE = -16
MAX_COORDINATE = 16
MAX_PARSEABLE_INPUT_LENGTH = 10
MAX_MOVES = 64
INVALID_RESULT = -1
ITERATION_CAP_RESULT = -2
CENTER_SCALE = 256
CENTER_BIAS = 4097
CENTER_BASE = 8194


def _pack_centers(centers: list[float]) -> int:
    codes = [int(center * CENTER_SCALE) + CENTER_BIAS for center in centers]
    if len(codes) != 2 or any(not 1 <= code <= 8193 for code in codes):
        return INVALID_RESULT
    return codes[0] * CENTER_BASE + codes[1]


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return packed final centers, or -1 for invalid framing/domain."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) < 2
    ):
        return INVALID_RESULT

    n = values[0]
    points = values[1:]
    if (
        not MIN_POINTS <= n <= MAX_POINTS
        or len(points) != n
        or any(not MIN_COORDINATE <= point <= MAX_COORDINATE for point in points)
        or any(left >= right for left, right in zip(points, points[1:]))
    ):
        return INVALID_RESULT

    points_f64 = [float(point) for point in points]
    step = n / 2.0
    second_index = math.floor(1.0 + step) - 1
    centers = [points_f64[0], points_f64[second_index]]

    for _ in range(MAX_MOVES):
        groups: list[list[float]] = [[], []]
        for point in points_f64:
            first_distance = math.sqrt((point - centers[0]) ** 2)
            second_distance = math.sqrt((point - centers[1]) ** 2)
            cluster = 1 if second_distance < first_distance else 0
            groups[cluster].append(point)
        if any(not group for group in groups):
            return INVALID_RESULT
        moved = [sum(group) / len(group) for group in groups]
        if moved == centers:
            return _pack_centers(moved)
        centers = moved

    return ITERATION_CAP_RESULT
