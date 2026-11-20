"""Independent parametric interval reference for Cohen–Sutherland fixtures.

This uses Liang–Barsky's four half-space inequalities instead of endpoint
outcodes and iterative endpoint replacement.
"""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1e300
SCALE = 1_000_000.0
MAX_COORDINATE_MICRO = 1_000_000_000
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12


def _valid(values: Sequence[int]) -> bool:
    if (not isinstance(values, (tuple, list)) or len(values) != 9
            or any(type(value) is not int for value in values)):
        return False
    selector, *coordinates = values
    if not 0 <= selector <= 4:
        return False
    if any(not -MAX_COORDINATE_MICRO <= value <= MAX_COORDINATE_MICRO
           for value in coordinates):
        return False
    return values[1] < values[3] and values[2] < values[4]


def _clip_interval(values: Sequence[int]) -> tuple[bool, tuple[float, float, float, float]]:
    _, xmin_raw, ymin_raw, xmax_raw, ymax_raw, x0_raw, y0_raw, x1_raw, y1_raw = values
    xmin, ymin, xmax, ymax, x0, y0, x1, y1 = (
        value / SCALE
        for value in (xmin_raw, ymin_raw, xmax_raw, ymax_raw,
                      x0_raw, y0_raw, x1_raw, y1_raw)
    )
    dx = x1 - x0
    dy = y1 - y0
    p = (-dx, dx, -dy, dy)
    q = (x0 - xmin, xmax - x0, y0 - ymin, ymax - y0)
    entering = 0.0
    leaving = 1.0

    for slope, clearance in zip(p, q):
        if slope == 0.0:
            if clearance < 0.0:
                return False, (x0, y0, x1, y1)
            continue
        crossing = clearance / slope
        if slope < 0.0:
            if crossing > leaving:
                return False, (x0, y0, x1, y1)
            entering = max(entering, crossing)
        else:
            if crossing < entering:
                return False, (x0, y0, x1, y1)
            leaving = min(leaving, crossing)

    clipped = (x0 + entering * dx, y0 + entering * dy,
               x0 + leaving * dx, y0 + leaving * dy)
    return True, clipped


def expected_result(values: Sequence[int]) -> float:
    """Return the selected coordinate or the bounded profile's status value."""
    if not _valid(values):
        return INVALID_RESULT
    accepted, endpoints = _clip_interval(values)
    selector = values[0]
    if selector == 4:
        return 1.0 if accepted else 0.0
    if not accepted:
        return INVALID_RESULT
    return endpoints[selector]


def agrees(actual: float, expected: float) -> bool:
    if actual == INVALID_RESULT or expected == INVALID_RESULT:
        return actual == expected
    return math.isclose(actual, expected, rel_tol=RELATIVE_TOLERANCE,
                        abs_tol=ABSOLUTE_TOLERANCE)
