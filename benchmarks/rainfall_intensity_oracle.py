"""Independent bounded oracle for the rainfall intensity package."""

from __future__ import annotations

INVALID_RESULT = -1e300


def rainfall_intensity(values: list[int]) -> float:
    if (len(values) != 6 or any(type(value) is not int for value in values)
            or not 1 <= values[0] <= 1_000
            or not 1 <= values[1] <= 3
            or not 1 <= values[2] <= 100
            or not 1 <= values[3] <= 3
            or not 1 <= values[4] <= 100
            or not 1 <= values[5] <= 1_000):
        return INVALID_RESULT
    coefficient_k, coefficient_a, coefficient_b, coefficient_c, period, duration = values
    return (coefficient_k * period**coefficient_a) / (duration + coefficient_b)**coefficient_c
