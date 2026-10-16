"""Oracle for the bounded Java coordinate-conversion methods."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
COORDINATE_LIMIT = 1_000_000.0
ANGLE_LIMIT_DEGREES = 36_000.0


def expected_result(values: list[int | float]) -> float:
    if not isinstance(values, list) or len(values) != 3:
        return INVALID_RESULT

    converted: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return INVALID_RESULT
        try:
            number = float(value)
        except (OverflowError, ValueError):
            return INVALID_RESULT
        if not math.isfinite(number):
            return INVALID_RESULT
        converted.append(number)

    first, second, selector_value = converted
    if selector_value != math.trunc(selector_value) or not 0 <= selector_value <= 3:
        return INVALID_RESULT
    selector = int(selector_value)

    if selector in (0, 1):
        if abs(first) > COORDINATE_LIMIT or abs(second) > COORDINATE_LIMIT:
            return INVALID_RESULT
        if selector == 0:
            return math.sqrt(first * first + second * second)
        return math.degrees(math.atan2(second, first))

    radius, theta_degrees = first, second
    if not 0 <= radius <= COORDINATE_LIMIT or abs(theta_degrees) > ANGLE_LIMIT_DEGREES:
        return INVALID_RESULT
    theta = math.radians(theta_degrees)
    return radius * (math.cos(theta) if selector == 2 else math.sin(theta))
