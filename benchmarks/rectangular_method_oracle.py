"""Oracle for the bounded left/right rectangle quadrature benchmark."""

from __future__ import annotations

import math

MIN_ENDPOINT_QUARTERS = -64
MAX_ENDPOINT_QUARTERS = 64
MIN_INTERVALS = 1
MAX_INTERVALS = 64
MAX_INPUT_LENGTH = 5  # admit one trailing value for malformed-input coverage
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 4
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    a_quarters, b_quarters, intervals, rule = values
    if (not MIN_ENDPOINT_QUARTERS <= a_quarters < b_quarters <= MAX_ENDPOINT_QUARTERS
            or not MIN_INTERVALS <= intervals <= MAX_INTERVALS
            or (b_quarters - a_quarters) % intervals != 0
            or rule not in (0, 1)):
        return INVALID_RESULT

    a = a_quarters / 4.0
    b = b_quarters / 4.0
    step = (b - a) / intervals
    x = a
    total = 0.0
    for _ in range(intervals):
        if rule == 0:
            total += (math.exp(x) / 2.0) * (math.cos(x) - math.sin(x)) * step
            x += step
        else:
            x += step
            total += (math.exp(x) / 2.0) * (math.cos(x) - math.sin(x)) * step
    return total
