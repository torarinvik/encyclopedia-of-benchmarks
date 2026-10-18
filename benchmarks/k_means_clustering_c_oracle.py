"""Oracle for the C k-means source variant with injected random labels."""

from __future__ import annotations

import math

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_POINTS = 3
MAX_POINTS = 8
MIN_COORDINATE = -16
MAX_COORDINATE = 16
MAX_PARSEABLE_INPUT_LENGTH = 18
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
    """Return packed centers, or -1 for invalid framing/domain."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) < 1
    ):
        return INVALID_RESULT

    n = values[0]
    if not MIN_POINTS <= n <= MAX_POINTS or len(values) != 1 + 2 * n:
        return INVALID_RESULT
    initial = values[1 : 1 + n]
    points = values[1 + n :]
    if (
        any(label not in (0, 1) for label in initial)
        or set(initial) != {0, 1}
        or any(not MIN_COORDINATE <= point <= MAX_COORDINATE for point in points)
        or any(left >= right for left, right in zip(points, points[1:]))
    ):
        return INVALID_RESULT

    labels = list(initial)
    for _ in range(MAX_MOVES):
        groups = [[float(point) for point, label in zip(points, labels) if label == cluster] for cluster in range(2)]
        if any(not group for group in groups):
            return INVALID_RESULT
        centers = [sum(group) / len(group) for group in groups]
        changed = 0
        next_labels: list[int] = []
        for point in points:
            first_distance = math.sqrt((float(point) - centers[0]) ** 2)
            second_distance = math.sqrt((float(point) - centers[1]) ** 2)
            label = 1 if second_distance < first_distance else 0
            changed += label != labels[len(next_labels)]
            next_labels.append(label)
        labels = next_labels
        if changed == 0:
            return _pack_centers(centers)

    return ITERATION_CAP_RESULT
