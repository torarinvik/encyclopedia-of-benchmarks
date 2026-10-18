"""Oracle for the deterministic general Rust k-means source variant."""

from __future__ import annotations

import math

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_POINTS = 2
MAX_POINTS = 8
MIN_COORDINATE = -16
MAX_COORDINATE = 16
MAX_PARSEABLE_INPUT_LENGTH = 10
MAX_MOVES = 256
INVALID_RESULT = -1
ITERATION_CAP_RESULT = -2


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the final label bitmask, or -1 for invalid framing/domain."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) < 2
    ):
        return INVALID_RESULT

    n = values[0]
    points_i64 = values[1:]
    if (
        not MIN_POINTS <= n <= MAX_POINTS
        or len(points_i64) != n
        or any(not MIN_COORDINATE <= point <= MAX_COORDINATE for point in points_i64)
        or any(left >= right for left, right in zip(points_i64, points_i64[1:]))
    ):
        return INVALID_RESULT

    points = [float(point) for point in points_i64]
    centers = [points[0], points[n // 2]]

    def assign(current: list[float]) -> list[int]:
        result: list[int] = []
        for point in points:
            d0 = (point - current[0]) ** 2
            d1 = (point - current[1]) ** 2
            result.append(1 if d1 < d0 else 0)
        return result

    labels = assign(centers)
    for _ in range(MAX_MOVES):
        groups = [[point for point, label in zip(points, labels) if label == cluster] for cluster in range(2)]
        if any(not group for group in groups):
            return INVALID_RESULT
        centers = [sum(group) / len(group) for group in groups]
        next_labels = assign(centers)
        if next_labels == labels:
            return sum(label << index for index, label in enumerate(labels))
        labels = next_labels

    return ITERATION_CAP_RESULT
