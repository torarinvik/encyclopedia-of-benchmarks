"""High-precision Decimal reference for Halley's cubic-root iteration."""

from __future__ import annotations

from decimal import Decimal, localcontext
import math

INVALID_RESULT = -1.0
MAX_ITERATIONS = 8


def expected_result(initial_x: float, iteration_count: float) -> float:
    if (not math.isfinite(initial_x) or not math.isfinite(iteration_count)
            or not 0.5 <= initial_x <= 2.0
            or not 0.0 <= iteration_count <= MAX_ITERATIONS
            or iteration_count != math.floor(iteration_count)):
        return INVALID_RESULT

    with localcontext() as context:
        context.prec = 90
        x = Decimal(str(initial_x))
        two = Decimal(2)
        three = Decimal(3)
        six = Decimal(6)
        for _ in range(int(iteration_count)):
            value = x * x * x - two
            first = three * x * x
            second = six * x
            denominator = two * first * first - value * second
            if denominator == 0:
                return INVALID_RESULT
            x -= (two * value * first) / denominator
        return float(x)
