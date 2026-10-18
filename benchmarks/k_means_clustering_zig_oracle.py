"""Oracle for the Zig f32 k-means source variant."""

from __future__ import annotations

import struct

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_POINTS = 2
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


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _distance_squared(left: float, right: float) -> float:
    delta = _f32(left - right)
    return _f32(_f32(delta * delta) + 0.0)


def _pack_centers(centers: list[float], counts: list[int]) -> int:
    codes = [int(_f32(center * _f32(CENTER_SCALE))) + CENTER_BIAS for center in centers]
    if len(codes) != 2 or any(not 1 <= code <= 8193 for code in codes):
        return INVALID_RESULT
    pair = codes[0] * CENTER_BASE + codes[1]
    return pair * 81 + counts[0] * 9 + counts[1]


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return packed centers/counts, or -1 for invalid framing/domain."""
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

    points = [_f32(float(point)) for point in points_i64]
    centers = [points[0], points[1]]
    old_counts = [0, 0]
    for _ in range(MAX_MOVES):
        sums = [0.0, 0.0]
        counts = [0, 0]
        for point in points:
            d0 = _distance_squared(point, centers[0])
            d1 = _distance_squared(centers[1], point)
            cluster = 1 if d1 < d0 else 0
            sums[cluster] = _f32(sums[cluster] + point)
            counts[cluster] += 1
        if any(count == 0 for count in counts):
            return INVALID_RESULT
        new_centers = [_f32(sums[i] / _f32(float(counts[i]))) for i in range(2)]
        if new_centers == centers and counts == old_counts:
            return _pack_centers(new_centers, counts)
        centers = new_centers
        old_counts = counts

    return ITERATION_CAP_RESULT
