"""Independent oracle for the bounded Prolangs-C recursive cubic root profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

COEFFICIENTS = (4, -4, -1, 1)
OUTPUT_BYTES = 24
INVALID_RESULT = -1
OUTPUT_ERROR = -2
RELATIVE_STEP_TOLERANCE = 5.0e-6
MAX_NEWTON_ITERATIONS = 40


def _evaluate_with_slope(coefficients: Sequence[float], point: float) -> tuple[float, float]:
    """Evaluate ascending-order coefficients and derivative in one Horner pass."""
    value = coefficients[-1]
    slope = value
    for coefficient in reversed(coefficients[1:-1]):
        value = value * point + coefficient
        slope = slope * point + value
    value = value * point + coefficients[0]
    return value, slope


def _newton(coefficients: Sequence[float], lower: float, upper: float) -> float:
    left, right = sorted((lower, upper))
    older = left
    estimate = (left + right) / 2.0
    updates = 0
    while abs(estimate - older) / abs(estimate) > RELATIVE_STEP_TOLERANCE and updates <= MAX_NEWTON_ITERATIONS:
        older = estimate
        value, slope = _evaluate_with_slope(coefficients, estimate)
        estimate -= value / slope
        updates += 1
    return estimate


def _source_order_roots() -> tuple[float, float, float]:
    # The source's root bound is sum(|a_i|)/|a_n|, with lower=-bound-1.
    polynomial = tuple(float(value) for value in COEFFICIENTS)
    bound = sum(abs(value) for value in polynomial) / abs(polynomial[-1])
    first = _newton(polynomial, -bound - 1.0, bound)

    # Synthetic division for ascending-order coefficients.
    quotient = [0.0, 0.0, polynomial[3]]
    quotient[1] = quotient[2] * first + polynomial[2]
    quotient[0] = quotient[1] * first + polynomial[1]
    discriminant = quotient[1] * quotient[1] - 4.0 * quotient[2] * quotient[0]
    radical = discriminant**0.5
    plus = (-quotient[1] + radical) / (2.0 * quotient[2])
    minus = (-quotient[1] - radical) / (2.0 * quotient[2])

    # The original benchmark calls Newton again on each root's +/-0.5 interval.
    return (
        first,
        _newton(polynomial, plus - 0.5, plus + 0.5),
        _newton(polynomial, minus - 0.5, minus + 0.5),
    )


def expected_output(
    values: Sequence[int],
    output_capacity: int = OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return source-order cubic roots as 3 little-endian binary64 values."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or len(values) != len(COEFFICIENTS)
        or any(type(value) is not int for value in values)
        or tuple(values) != COEFFICIENTS
    ):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, struct.pack("<3d", *_source_order_roots())
