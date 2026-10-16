"""Oracle for the bounded Newton-Raphson cubic-root benchmark."""
from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
MAX_INPUT_LENGTH = 3
EXACT_INPUT_LENGTH = 2


def _equation(x: float) -> float:
    return math.pow(x, 3.0) - (4.0 * x) - 9.0


def _derivative(x: float) -> float:
    return 3.0 * math.pow(x, 2.0) - 4.0


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != EXACT_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    x0_milli, iteration_limit = values
    if not 2000 <= x0_milli <= 4000 or not 1 <= iteration_limit <= 32:
        return INVALID_RESULT
    c = x0_milli / 1000.0
    z = math.nan
    for _ in range(iteration_limit):
        m = _equation(c)
        n = _derivative(c)
        z = c - (m / n)
        c = z
        if abs(m) < 1e-10:
            break
    return z if math.isfinite(z) else INVALID_RESULT
