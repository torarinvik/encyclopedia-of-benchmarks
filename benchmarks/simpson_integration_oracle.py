"""Oracle for the bounded pinned Java/JavaScript Simpson integrator."""

from __future__ import annotations

import math

SCALE = 1_000_000
MAX_INTERVALS = 128
MAX_ENDPOINT_MICRO = 10_000_000
MAX_INPUT_LENGTH = 4  # admit one extra packed value for malformed-input coverage
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    intervals, a_micro, b_micro = values
    if (intervals < 2 or intervals > MAX_INTERVALS or intervals % 2 != 0
            or not -MAX_ENDPOINT_MICRO <= a_micro <= MAX_ENDPOINT_MICRO
            or not -MAX_ENDPOINT_MICRO <= b_micro <= MAX_ENDPOINT_MICRO
            or a_micro > b_micro):
        return INVALID_RESULT

    a = a_micro / SCALE
    b = b_micro / SCALE
    if a == b:
        return 0.0

    h = (b - a) / intervals
    xi = a
    total = 0.0
    for index in range(intervals + 1):
        sample = math.exp(-xi) * (4.0 - math.pow(xi, 2.0))
        if index == 0 or index == intervals:
            total += sample
        elif index % 2 != 0:
            total += 4.0 * sample
        else:
            total += 2.0 * sample
        xi += h

    return (h / 3.0) * total
