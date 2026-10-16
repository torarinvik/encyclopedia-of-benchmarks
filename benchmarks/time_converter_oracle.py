"""Oracle for the pinned Java time conversion and three-decimal rounding."""

from __future__ import annotations

import math

SCALE = 1_000_000
MAX_TIME_MICRO = 1_000_000_000
MAX_INPUT_LENGTH = 4  # admit one extra packed value
INVALID_RESULT = -1.0e300
SECONDS_PER_UNIT = (1.0, 60.0, 3600.0, 86400.0, 604800.0, 2629800.0, 31557600.0)


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    time_micro, from_unit, to_unit = values
    if not 0 <= time_micro <= MAX_TIME_MICRO or not 0 <= from_unit < len(SECONDS_PER_UNIT) or not 0 <= to_unit < len(SECONDS_PER_UNIT):
        return INVALID_RESULT

    time_value = time_micro / SCALE
    seconds_value = time_value * SECONDS_PER_UNIT[from_unit]
    converted = seconds_value / SECONDS_PER_UNIT[to_unit]
    rounded = math.floor(converted * 1000.0 + 0.5)
    return rounded / 1000.0
