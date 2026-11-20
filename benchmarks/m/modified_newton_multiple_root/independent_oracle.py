"""High-precision Decimal reference for the multiplicity-corrected update."""

from __future__ import annotations

from decimal import Decimal, localcontext
import math

INVALID_RESULT = -1.0
MAX_ITERATIONS = 8


def expected_result(initial_x: float, iteration_count: float) -> float:
    if (not math.isfinite(initial_x) or not math.isfinite(iteration_count)
            or not 1.0 <= initial_x <= 2.0
            or not 0.0 <= iteration_count <= MAX_ITERATIONS
            or iteration_count != math.floor(iteration_count)):
        return INVALID_RESULT

    with localcontext() as context:
        context.prec = 90
        x = Decimal(str(initial_x))
        one = Decimal(1)
        two = Decimal(2)
        three = Decimal(3)
        for _ in range(int(iteration_count)):
            if x == one:
                break
            offset = x - one
            value = offset * offset * (x + two)
            derivative = three * offset * (x + one)
            if derivative == 0:
                return INVALID_RESULT
            x -= two * (value / derivative)
        return float(x)
