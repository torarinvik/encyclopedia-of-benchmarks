"""Primary bounded adaptive-Simpson ABI oracle."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
SCALE = 1_000_000
MIN_ENDPOINT_MICRO = -2_000_000
MAX_ENDPOINT_MICRO = 2_000_000
MIN_TOLERANCE_EXPONENT = 7
MAX_TOLERANCE_EXPONENT = 8
MIN_DEPTH = 8
MAX_DEPTH = 12
MAX_VALID_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_OUTPUT_ELEMENTS = 1
ABSOLUTE_TOLERANCE = 1e-7
RELATIVE_TOLERANCE = 1e-7


def _finite(value: object) -> bool:
    return (type(value) in (int, float)
            and math.isfinite(float(value)))


def _parse(values: Sequence[int | float], input_is_null: bool,
           input_length: int) -> tuple[int, float, float, float, int] | None:
    if (not isinstance(values, (tuple, list))
            or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(not _finite(value) for value in values)):
        return None
    if input_is_null:
        return None
    if input_length != len(values) or input_length != MAX_VALID_INPUT_LENGTH:
        return None
    integers: list[int] = []
    for value in values:
        numeric = float(value)
        if not numeric.is_integer():
            return None
        integers.append(int(numeric))
    function_id, a_micro, b_micro, exponent, depth = integers
    if (function_id not in (0, 1, 2)
            or not MIN_ENDPOINT_MICRO <= a_micro <= MAX_ENDPOINT_MICRO
            or not MIN_ENDPOINT_MICRO <= b_micro <= MAX_ENDPOINT_MICRO
            or a_micro > b_micro
            or not MIN_TOLERANCE_EXPONENT <= exponent <= MAX_TOLERANCE_EXPONENT
            or not MIN_DEPTH <= depth <= MAX_DEPTH):
        return None
    return function_id, a_micro / SCALE, b_micro / SCALE, 10.0 ** (-exponent), depth


def _function(function_id: int, x: float) -> float:
    if function_id == 0:
        return x * x * x * x
    if function_id == 1:
        return math.sin(x)
    return 1.0 / (1.0 + x * x)


def _simpson(a: float, b: float, fa: float, fm: float, fb: float) -> float:
    return (b - a) * (fa + 4.0 * fm + fb) / 6.0


def _refine(function_id: int, a: float, b: float, fa: float, fm: float,
            fb: float, whole: float, tolerance: float, depth: int) -> float:
    midpoint = (a + b) * 0.5
    left_midpoint = (a + midpoint) * 0.5
    right_midpoint = (midpoint + b) * 0.5
    flm = _function(function_id, left_midpoint)
    frm = _function(function_id, right_midpoint)
    left = _simpson(a, midpoint, fa, flm, fm)
    right = _simpson(midpoint, b, fm, frm, fb)
    delta = left + right - whole
    if depth == 0 or abs(delta) <= 15.0 * tolerance:
        return left + right + delta / 15.0
    return (_refine(function_id, a, midpoint, fa, flm, fm, left,
                    tolerance * 0.5, depth - 1)
            + _refine(function_id, midpoint, b, fm, frm, fb, right,
                      tolerance * 0.5, depth - 1))


def _integrate(parsed: tuple[int, float, float, float, int]) -> float:
    function_id, a, b, tolerance, depth = parsed
    if a == b:
        return 0.0
    midpoint = (a + b) * 0.5
    fa, fm, fb = (_function(function_id, x) for x in (a, midpoint, b))
    whole = _simpson(a, b, fa, fm, fb)
    return _refine(function_id, a, b, fa, fm, fb, whole, tolerance, depth)


def expected_output(
        values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False, input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    """Return the ABI result; validate the input before output capacity."""
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _parse(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if (type(capacity) is not int or capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    result = _integrate(parsed)
    return (1, (result,)) if math.isfinite(result) else (INVALID_RESULT, ())
