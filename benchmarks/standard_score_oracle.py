"""Bounded source-formula oracle for standard_score."""

import math

INVALID_RESULT = -1e300


def expected_result(value: float, mean: float, std_dev: float) -> float:
    if (not all(math.isfinite(item) for item in (value, mean, std_dev))
            or abs(value) > 1_000_000.0 or abs(mean) > 1_000_000.0
            or abs(std_dev) < 1e-6 or abs(std_dev) > 1_000_000.0):
        return INVALID_RESULT
    return (value - mean) / std_dev
