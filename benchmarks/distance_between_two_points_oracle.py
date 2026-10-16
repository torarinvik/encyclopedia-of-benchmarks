"""Independent bounded oracle for the two-dimensional point-distance benchmark."""

from __future__ import annotations

import math

COORDINATE_MINIMUM = -1_000_000
COORDINATE_MAXIMUM = 1_000_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the source formula's Euclidean distance for four coordinates."""
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(value) is not int for value in values)
            or any(not COORDINATE_MINIMUM <= value <= COORDINATE_MAXIMUM for value in values)):
        return INVALID_RESULT
    x1, y1, x2, y2 = values
    delta_x = x2 - x1
    delta_y = y2 - y1
    return math.sqrt(float(delta_x * delta_x + delta_y * delta_y))
