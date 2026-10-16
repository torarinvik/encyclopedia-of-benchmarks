"""Independent oracle for Spearman correlation with average ranks for ties."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
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
    if not 2 <= count <= MAX_OBSERVATIONS or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    x_values = values[1:1 + count]
    y_values = values[1 + count:]
    if any(abs(value) > MAX_ABS_VALUE for value in x_values + y_values):
        return INVALID_RESULT

    def ranks(samples: tuple[int, ...] | list[int]) -> list[float]:
        result = []
        for value in samples:
            less = sum(other < value for other in samples)
            equal = sum(other == value for other in samples)
            result.append(float(less) + (float(equal) + 1.0) / 2.0)
        return result

    x_ranks = ranks(x_values)
    y_ranks = ranks(y_values)
    mean_rank = (count + 1) / 2.0
    covariance = variance_x = variance_y = 0.0
    for x_rank, y_rank in zip(x_ranks, y_ranks):
        dx = x_rank - mean_rank
        dy = y_rank - mean_rank
        covariance += dx * dy
        variance_x += dx * dx
        variance_y += dy * dy
    if variance_x == 0.0 or variance_y == 0.0:
        return INVALID_RESULT
    return covariance / math.sqrt(variance_x * variance_y)
