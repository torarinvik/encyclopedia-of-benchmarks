"""Independent high-precision reference using a Decimal cosine series."""

from __future__ import annotations

from decimal import Decimal, localcontext
import math


def _cosine_taylor(value: Decimal) -> Decimal:
    square = value * value
    term = Decimal(1)
    total = term
    for index in range(1, 40):
        term = -(term * square) / Decimal((2 * index - 1) * (2 * index))
        total += term
        if abs(term) < Decimal("1e-82"):
            break
    return total


def expected_result(initial_x: float, source_n: float) -> float:
    if (not math.isfinite(initial_x) or not math.isfinite(source_n)
            or not 0.0 <= initial_x <= 2.0
            or not 0.0 <= source_n <= 64.0
            or source_n != math.floor(source_n)):
        return -1.0

    with localcontext() as context:
        context.prec = 90
        value = Decimal(str(initial_x))
        two = Decimal(2)
        for _ in range(int(source_n) + 1):
            value = (_cosine_taylor(value) + two) / two
        return float(value)
