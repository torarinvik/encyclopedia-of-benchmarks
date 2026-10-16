"""Independent oracle for the bounded standard Pearson correlation benchmark."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
MIN_OBSERVATIONS = 2
MAX_OBSERVATIONS = 128
MAX_ABS_VALUE = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_OBSERVATIONS
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def expected_result(values: tuple[int, ...] | list[int]) -> float:
    if (not isinstance(values, (tuple, list)) or len(values) < 1
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    count = values[0]
    if (not MIN_OBSERVATIONS <= count <= MAX_OBSERVATIONS
            or len(values) != 1 + 2 * count):
        return INVALID_RESULT
    x_values = values[1:1 + count]
    y_values = values[1 + count:]
    if any(abs(value) > MAX_ABS_VALUE for value in x_values + y_values):
        return INVALID_RESULT

    mean_x = sum(x_values) / count
    mean_y = sum(y_values) / count
    covariance = 0.0
    variance_x = 0.0
    variance_y = 0.0
    for x_value, y_value in zip(x_values, y_values):
        dx = float(x_value) - mean_x
        dy = float(y_value) - mean_y
        covariance += dx * dy
        variance_x += dx * dx
        variance_y += dy * dy
    if variance_x == 0.0 or variance_y == 0.0:
        return INVALID_RESULT
    return covariance / math.sqrt(variance_x * variance_y)
