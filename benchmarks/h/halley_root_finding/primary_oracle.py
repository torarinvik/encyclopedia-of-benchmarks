"""Binary64 primary reference for Halley's cubic-root iteration."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0
MAX_ITERATIONS = 8


def expected_result(initial_x: float, iteration_count: float) -> float:
    if (not math.isfinite(initial_x) or not math.isfinite(iteration_count)
            or not 0.5 <= initial_x <= 2.0
            or not 0.0 <= iteration_count <= MAX_ITERATIONS
            or iteration_count != math.floor(iteration_count)):
        return INVALID_RESULT

    x = float(initial_x)
    for _ in range(int(iteration_count)):
        value = x * x * x - 2.0
        first = 3.0 * x * x
        second = 6.0 * x
        denominator = 2.0 * first * first - value * second
        if denominator == 0.0 or not math.isfinite(denominator):
            return INVALID_RESULT
        x -= (2.0 * value * first) / denominator
        if not math.isfinite(x):
            return INVALID_RESULT
    return x
