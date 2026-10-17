"""Oracle for the bounded Python Simpson-rule implementation."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1e300
SUPPORTED_BOUNDS = (1.0, 2.0, 3.0)
FIXED_STEPS = 10.0
INPUT_SCALED_TOLERANCE = 1e-12


def simpson_rule_value(b: float, steps: float) -> float:
    """Reproduce method_2, make_points, and the module's default f(x)=x^2."""
    if type(b) not in (int, float) or type(steps) not in (int, float):
        return INVALID_RESULT
    try:
        upper = float(b)
        step_count = float(steps)
    except (OverflowError, ValueError):
        return INVALID_RESULT
    if (not math.isfinite(upper) or not math.isfinite(step_count)
            or upper not in SUPPORTED_BOUNDS or step_count != FIXED_STEPS):
        return INVALID_RESULT

    h = (upper - 0.0) / step_count
    x = 0.0 + h
    total = 0.0
    total += (h / 3.0) * ((0.0 - 0.0) * (0.0 - 0.0))
    count = 2
    while x < (upper - h):
        weight = 4 - 2 * (count % 2)
        total += (h / 3.0) * weight * ((x - 0.0) * (x - 0.0))
        count += 1
        x = x + h
    total += (h / 3.0) * ((upper - 0.0) * (upper - 0.0))
    return total


def expected_result(values: Sequence[int | float]) -> float:
    """Return the binary64 result for one [b, steps] pair."""
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) not in (int, float) for value in values)):
        return INVALID_RESULT
    return simpson_rule_value(values[0], values[1])
