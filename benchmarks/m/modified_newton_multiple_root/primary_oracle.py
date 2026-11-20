"""Binary64 primary reference for the known-multiplicity Newton update."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0
MAX_ITERATIONS = 8


def expected_result(initial_x: float, iteration_count: float) -> float:
    if (not math.isfinite(initial_x) or not math.isfinite(iteration_count)
            or not 1.0 <= initial_x <= 2.0
            or not 0.0 <= iteration_count <= MAX_ITERATIONS
            or iteration_count != math.floor(iteration_count)):
        return INVALID_RESULT

    x = float(initial_x)
    for _ in range(int(iteration_count)):
        if x == 1.0:
            break
        offset = x - 1.0
        value = offset * offset * (x + 2.0)
        derivative = 3.0 * offset * (x + 1.0)
        if derivative == 0.0 or not math.isfinite(derivative):
            return INVALID_RESULT
        x -= 2.0 * (value / derivative)
        if not math.isfinite(x) or not 1.0 <= x <= 2.0:
            return INVALID_RESULT
    return x
