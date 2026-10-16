"""Bounded scalar contract for the pinned MATLAB parameterized sigmoid."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
X_MIN = -10.0
X_MAX = 10.0
SLOPE_MIN = -10.0
SLOPE_MAX = 10.0


def expected_result(x: float, slope: float) -> float:
    if (
        not math.isfinite(x)
        or not math.isfinite(slope)
        or x < X_MIN
        or x > X_MAX
        or slope < SLOPE_MIN
        or slope > SLOPE_MAX
    ):
        return INVALID_RESULT
    return 1.0 / (1.0 + math.exp(-slope * x))

