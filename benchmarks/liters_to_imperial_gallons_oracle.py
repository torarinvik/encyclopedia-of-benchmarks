"""Independent oracle for pinned liters-to-Imperial-gallons conversion."""

from __future__ import annotations

import math

MIN_VALUE = -1e100
MAX_VALUE = 1e100
INVALID_RESULT = -1e300
LITERS_PER_IMPERIAL_GALLON = 4.54609


def expected_result(liters: int | float) -> float:
    if (type(liters) not in (int, float) or not math.isfinite(liters)
            or not MIN_VALUE <= liters <= MAX_VALUE):
        return INVALID_RESULT
    return liters / LITERS_PER_IMPERIAL_GALLON
