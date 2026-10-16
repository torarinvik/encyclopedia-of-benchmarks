"""Bounded oracle for nth derivatives computed with dual-number coefficients."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_POSITION = 1.0
MAX_POWER = 8
MAX_ORDER = 8


def expected_result(position: float, power: float, order: float) -> float:
    if (not all(math.isfinite(value) for value in (position, power, order))
            or not -MAX_POSITION <= position <= MAX_POSITION
            or not power.is_integer() or not 0 <= power <= MAX_POWER
            or not order.is_integer() or not 0 <= order <= min(int(power), MAX_ORDER)):
        return INVALID_RESULT
    exponent = int(power)
    derivative_order = int(order)
    if derivative_order == 0:
        return position ** exponent
    multiplier = 1
    for factor in range(exponent, exponent - derivative_order, -1):
        multiplier *= factor
    return float(multiplier) * (position ** (exponent - derivative_order))
