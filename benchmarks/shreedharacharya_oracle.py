"""Oracle for the bounded Dart Shreedharacharya quadratic-root function."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_INPUT_LENGTH = 3
MAX_COEFFICIENT = 1_000_000.0
MIN_ABS_LEADING_COEFFICIENT = 1e-6
MAX_OUTPUT_ELEMENTS = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except (OverflowError, ValueError):
        return False


def expected_output(
    values: Sequence[int | float], output_capacity: int | None = None
) -> tuple[int, list[float]]:
    """Return the Dart source's zero, one, or two real roots in source order."""
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(not _finite_number(value) for value in values)):
        return INVALID_RESULT, []

    a, b, c = (float(value) for value in values)
    if (abs(a) < MIN_ABS_LEADING_COEFFICIENT or abs(a) > MAX_COEFFICIENT
            or abs(b) > MAX_COEFFICIENT or abs(c) > MAX_COEFFICIENT):
        return INVALID_RESULT, []

    discriminant = b * b - 4.0 * a * c
    if not math.isfinite(discriminant):
        return INVALID_RESULT, []
    if discriminant < 0.0:
        roots: list[float] = []
    elif discriminant == 0.0:
        roots = [-b / (2.0 * a)]
    else:
        square_root = math.sqrt(discriminant)
        denominator = 2.0 * a
        roots = [(-b + square_root) / denominator,
                 (-b - square_root) / denominator]
    if any(not math.isfinite(root) for root in roots):
        return INVALID_RESULT, []

    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, []
        if output_capacity < len(roots):
            return OUTPUT_ERROR, []
    return len(roots), roots
