"""Independent oracle for the bounded Rodinia Leukocyte GICOV recurrence."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

INVALID_RESULT = -1.0e300
ELLIPSE_COUNT = 7
MIN_POINTS = 2
MAX_POINTS = 16
MAX_INPUT_LENGTH = 1 + ELLIPSE_COUNT * MAX_POINTS
SAMPLE_SCALE = 1_000_000


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def _add(a: float, b: float) -> float:
    return _f32(a + b)


def _sub(a: float, b: float) -> float:
    return _f32(a - b)


def _mul(a: float, b: float) -> float:
    return _f32(a * b)


def _div(a: float, b: float) -> float:
    return _f32(a / b)


def _decode(raw: int) -> float:
    return _div(_f32(raw), _f32(SAMPLE_SCALE))


def expected_result(values: Sequence[int]) -> float:
    """Return max GICOV over seven sample rows, or the finite invalid sentinel."""
    if not values or any(type(value) is not int for value in values):
        return INVALID_RESULT
    point_count = values[0]
    if point_count < MIN_POINTS or point_count > MAX_POINTS:
        return INVALID_RESULT
    if len(values) != 1 + ELLIPSE_COUNT * point_count:
        return INVALID_RESULT
    if any(type(value) is not int or abs(value) > SAMPLE_SCALE for value in values[1:]):
        return INVALID_RESULT

    best = _f32(0.0)
    for ellipse in range(ELLIPSE_COUNT):
        running_sum = _f32(0.0)
        running_mean = _f32(0.0)
        m2 = _f32(0.0)
        base = 1 + ellipse * point_count
        for point in range(point_count):
            sample = _decode(values[base + point])
            running_sum = _add(running_sum, sample)
            delta = _sub(sample, running_mean)
            running_mean = _add(running_mean, _div(delta, _f32(point + 1)))
            m2 = _add(m2, _mul(delta, _sub(sample, running_mean)))

        # The source replaces the running mean with sum/N before scoring.
        mean = _div(running_sum, _f32(point_count))
        variance = _div(m2, _f32(point_count - 1))
        # Rows that become constant after binary32 decoding divide by zero in
        # the CUDA kernel and are outside this finite-result profile.
        if not variance > 0.0 or not math.isfinite(variance):
            return INVALID_RESULT
        score = _div(_mul(mean, mean), variance)
        if not math.isfinite(score):
            return INVALID_RESULT
        if score > best:
            best = score
    return float(best)
