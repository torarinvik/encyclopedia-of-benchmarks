"""Independent oracle for bounded C and Python secant-method variants."""

from __future__ import annotations

import math

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
EXACT_INPUT_LENGTH = 2
MAX_INPUT_LENGTH = 3
INVALID_RESULT = -1.0e300


def _c_variant() -> float:
    x0, x1 = 0.2, 0.5
    tolerance = 100.0 / 1_000_000.0
    for _ in range(99):
        f1 = x1 * x1 - 3.0
        f0 = x0 * x0 - 3.0
        x2 = x1 - f1 * (x1 - x0) / (f1 - f0)
        x0, x1 = x1, x2
        if abs(x1 - x0) < tolerance:
            return x2
    return -1.0


def _python_function(value: float) -> float:
    return 8.0 * value - 2.0 * math.exp(-value)


def _python_variant(repeats: int) -> float:
    x0, x1 = 1.0, 3.0
    for _ in range(repeats):
        f1 = _python_function(x1)
        f0 = _python_function(x0)
        x2 = x1 - (f1 * (x1 - x0)) / (f1 - f0)
        x0, x1 = x1, x2
    return x1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the selected source variant's scalar result or invalid sentinel."""
    if (not isinstance(values, (list, tuple)) or len(values) != EXACT_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    variant, control = values
    if variant == 0 and control == 100:
        result = _c_variant()
    elif variant == 1 and 0 <= control <= 2:
        result = _python_variant(control)
    else:
        return INVALID_RESULT
    return result if math.isfinite(result) else INVALID_RESULT
