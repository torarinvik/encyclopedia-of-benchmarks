"""Oracle for R type-7 IQR outlier indices encoded as a bit mask."""

from __future__ import annotations

import math

INVALID_RESULT = -1
MAX_LENGTH = 62
MAX_ABS_VALUE = 1_000_000
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def _type7_quantile(sorted_values: list[int], probability: float) -> float:
    count = len(sorted_values)
    h = (count - 1) * probability + 1.0
    order = int(h)
    fraction = h - order
    lower = order - 1
    if fraction == 0.0 or lower + 1 >= count:
        return float(sorted_values[lower])
    return ((1.0 - fraction) * float(sorted_values[lower])
            + fraction * float(sorted_values[lower + 1]))


def expected_result(values: tuple[int, ...] | list[int]) -> int:
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or any(abs(value) > MAX_ABS_VALUE for value in values)):
        return INVALID_RESULT
    sorted_values = sorted(values)
    q1 = _type7_quantile(sorted_values, 0.25)
    q3 = _type7_quantile(sorted_values, 0.75)
    iqr = q3 - q1
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr
    mask = 0
    for index, value in enumerate(values):
        if value < lower_bound or value > upper_bound:
            mask |= 1 << index
    return mask
