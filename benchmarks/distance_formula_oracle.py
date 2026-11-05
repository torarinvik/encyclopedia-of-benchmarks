"""Independent integer-arithmetic oracle for the pinned distance expression."""
from __future__ import annotations

import math

COORDINATE_BOUND = 1_000_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(value) is not int or abs(value) > COORDINATE_BOUND
                   for value in values)):
        return INVALID_RESULT
    x1, _y1, x2, y2 = values
    # Preserve the pinned source's second subtraction, including x1.
    dx, dy = x2 - x1, y2 - x1
    return math.sqrt(float(dx * dx + dy * dy))
