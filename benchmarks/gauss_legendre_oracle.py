"""High-precision reference for the bounded Gauss-Legendre pi iteration."""

from __future__ import annotations

import math
from collections.abc import Sequence
from decimal import Decimal, localcontext

MAX_ITERATIONS = 8
INVALID_RESULT = -1e300


def _pi_after_iterations(iterations: int) -> float:
    """Evaluate the arithmetic-geometric recurrence with extra precision."""
    with localcontext() as context:
        context.prec = 80
        a = Decimal(1)
        b = Decimal(1) / Decimal(2).sqrt()
        t = Decimal(1) / Decimal(4)
        p = Decimal(1)
        for _ in range(iterations):
            next_a = (a + b) / Decimal(2)
            next_b = (a * b).sqrt()
            difference = a - next_a
            next_t = t - p * difference * difference
            next_p = Decimal(2) * p
            a, b, t, p = next_a, next_b, next_t, next_p
        return float((a + b) * (a + b) / (Decimal(4) * t))


def expected_result(values: Sequence[int | float]) -> float:
    """Return the source result for one finite integral iteration count."""
    if not isinstance(values, (list, tuple)) or len(values) != 1:
        return INVALID_RESULT
    value = values[0]
    if type(value) not in (int, float):
        return INVALID_RESULT
    value = float(value)
    if not math.isfinite(value) or not 0 <= value <= MAX_ITERATIONS or not value.is_integer():
        return INVALID_RESULT
    return _pi_after_iterations(int(value))
