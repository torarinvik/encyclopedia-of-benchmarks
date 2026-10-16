"""Bounded scalar contract for the pinned MATLAB ELU function."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
X_MIN = -100.0
X_MAX = 100.0
ALPHA_MIN = -1_000_000.0
ALPHA_MAX = 1_000_000.0


def expected_result(x: float, alpha: float) -> float:
    if (
        not math.isfinite(x)
        or not math.isfinite(alpha)
        or x < X_MIN
        or x > X_MAX
        or alpha < ALPHA_MIN
        or alpha > ALPHA_MAX
    ):
        return INVALID_RESULT
    if x == 0.0:
        return 0.0
    if x < 0.0:
        return alpha * (math.exp(x) - 1.0)
    return x

