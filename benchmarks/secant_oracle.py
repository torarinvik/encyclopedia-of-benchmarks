"""Independent oracle for the bounded MATLAB secant benchmark."""

from __future__ import annotations

import math

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
EXACT_INPUT_LENGTH = 5
MAX_INPUT_LENGTH = 6
INVALID_RESULT = -1.0e300

MIN_A_MICRO = 1_000_000
MAX_A_MICRO = 1_500_000
MIN_B_MICRO = 1_600_000
MAX_B_MICRO = 2_000_000
MIN_TOLERANCE_NANO = 1
MAX_TOLERANCE_NANO = 100_000
MAX_UPDATES = 32


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the source-compatible secant result or finite invalid sentinel."""
    if (not isinstance(values, (list, tuple)) or len(values) != EXACT_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    selector, a_micro, b_micro, tolerance_nano, max_updates = values
    if (selector != 0 or not MIN_A_MICRO <= a_micro <= MAX_A_MICRO
            or not MIN_B_MICRO <= b_micro <= MAX_B_MICRO or a_micro >= b_micro
            or not MIN_TOLERANCE_NANO <= tolerance_nano <= MAX_TOLERANCE_NANO
            or not 0 <= max_updates <= MAX_UPDATES):
        return INVALID_RESULT

    x0 = a_micro / 1_000_000.0
    x1 = b_micro / 1_000_000.0
    tolerance = tolerance_nano / 1_000_000_000.0
    for _ in range(max_updates + 1):
        f1 = x1 * x1 - 3.0
        if abs(f1) <= tolerance:
            return x1
        if _ == max_updates:
            break
        f0 = x0 * x0 - 3.0
        denominator = f1 - f0
        if denominator == 0.0:
            return INVALID_RESULT
        x2 = x1 - f1 * (x1 - x0) / denominator
        if not math.isfinite(x2):
            return INVALID_RESULT
        x0, x1 = x1, x2
    return INVALID_RESULT
