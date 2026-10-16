"""Independent oracle for the pinned liters-to-U.S.-gallons conversion."""

from __future__ import annotations

import math

MIN_VALUE = -1e100
MAX_VALUE = 1e100
INVALID_RESULT = -1e300
LITERS_PER_US_GALLON = 3.785411784


def expected_result(liters: int | float) -> float:
    if (type(liters) not in (int, float) or not math.isfinite(liters)
            or not MIN_VALUE <= liters <= MAX_VALUE):
        return INVALID_RESULT
    return liters / LITERS_PER_US_GALLON
