"""Source-shaped oracle for the bounded JavaScript Circle class benchmark."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MIN_RADIUS = -1_000_000.0
MAX_RADIUS = 1_000_000.0


def expected_result(radius: float, operation: float) -> float:
    """Return the selected Circle method result, or INVALID_RESULT."""
    if (type(radius) not in (int, float) or type(operation) not in (int, float)
            or not math.isfinite(float(radius)) or not math.isfinite(float(operation))):
        return INVALID_RESULT
    radius = float(radius)
    operation = float(operation)
    if not MIN_RADIUS <= radius <= MAX_RADIUS or operation not in (0.0, 1.0):
        return INVALID_RESULT
    if operation == 0.0:
        return radius * 2.0 * math.pi
    return math.pow(radius, 2.0) * math.pi
