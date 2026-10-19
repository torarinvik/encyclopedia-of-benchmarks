"""Independent root-isolation oracle for the bounded MiBench cubic kernel."""

from __future__ import annotations

import math
from collections.abc import Sequence

COEFFICIENT_COUNT = 4
MAX_ABS_COEFFICIENT = 100.0
MIN_ABS_LEADING_COEFFICIENT = 1.0
MAX_OUTPUT_ELEMENTS = 3
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _bounded_coefficients(values: object) -> tuple[float, float, float, float] | None:
    if not isinstance(values, (list, tuple)) or len(values) != COEFFICIENT_COUNT:
        return None
    converted: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(number) or abs(number) > MAX_ABS_COEFFICIENT:
            return None
        converted.append(number)
    a, b, c, d = converted
    if abs(a) < MIN_ABS_LEADING_COEFFICIENT:
        return None
    a1, a2, a3 = b / a, c / a, d / a
    q = (a1 * a1 - 3.0 * a2) / 9.0
    r = (2.0 * a1 * a1 * a1 - 9.0 * a1 * a2 + 27.0 * a3) / 54.0
    if r * r - q * q * q == 0.0:
        return None
    return a, b, c, d


def _polynomial(coefficients: tuple[float, float, float, float], x: float) -> float:
    a, b, c, d = coefficients
    return ((a * x + b) * x + c) * x + d


def _roots_by_interval_isolation(
    coefficients: tuple[float, float, float, float],
) -> list[float] | None:
    """Find simple real roots by bracketing at the derivative's critical points."""
    a, b, c, d = coefficients
    derivative_discriminant = b * b - 3.0 * a * c
    critical_points: list[float] = []
    if derivative_discriminant > 0.0:
        square_root = math.sqrt(derivative_discriminant)
        critical_points = [
            (-b - square_root) / (3.0 * a),
            (-b + square_root) / (3.0 * a),
        ]
        critical_points.sort()
        # Repeated polynomial roots lie at a derivative critical point. They
        # are outside this bounded profile because the upstream formula is
        # singular for the triple-root case and unstable at a double root.
        if any(_polynomial(coefficients, point) == 0.0 for point in critical_points):
            return None

    bound = 1.0 + max(abs(b / a), abs(c / a), abs(d / a))
    points = [-bound]
    points.extend(point for point in critical_points if -bound < point < bound)
    points.append(bound)
    roots: list[float] = []
    for lower, upper in zip(points, points[1:]):
        lower_value = _polynomial(coefficients, lower)
        upper_value = _polynomial(coefficients, upper)
        if lower_value == 0.0:
            roots.append(lower)
            continue
        if upper_value == 0.0:
            roots.append(upper)
            continue
        if (lower_value < 0.0) == (upper_value < 0.0):
            continue
        lo, hi = lower, upper
        lo_value = lower_value
        for _ in range(120):
            middle = (lo + hi) * 0.5
            middle_value = _polynomial(coefficients, middle)
            if middle_value == 0.0:
                lo = hi = middle
                break
            if (lo_value < 0.0) != (middle_value < 0.0):
                hi = middle
            else:
                lo, lo_value = middle, middle_value
        roots.append((lo + hi) * 0.5)
    roots.sort()
    if len(roots) not in (1, 3):
        return None
    return roots


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return source-ordered real roots and the float64-slice ABI result."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, []
    coefficients = _bounded_coefficients(values)
    if coefficients is None:
        return INVALID_RESULT, []
    roots = _roots_by_interval_isolation(coefficients)
    if roots is None:
        return INVALID_RESULT, []
    # SolveCubic emits the smallest root, then the largest, then the middle
    # root in its trigonometric branch.
    source_order = roots if len(roots) == 1 else [roots[0], roots[2], roots[1]]
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < len(source_order)
    ):
        return OUTPUT_ERROR, []
    return len(source_order), source_order
