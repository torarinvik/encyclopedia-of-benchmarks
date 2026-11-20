"""Primary finite Takahasi–Mori transformed-trapezoid reference."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_P = 2
MAX_P = 4
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_ELEMENTS = 1
WORKSPACE_ELEMENTS = 1
WORKSPACE_BYTES = 8
ABSOLUTE_TOLERANCE = 1e-5
RELATIVE_TOLERANCE = 1e-12
PI = 3.14159265358979323846264338327950288


def _finite(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _integer(value: object, low: int, high: int) -> int | None:
    if not _finite(value):
        return None
    converted = float(value)
    if not converted.is_integer() or converted < low or converted > high:
        return None
    return int(converted)


def _decode(values: Sequence[int | float], input_is_null: bool,
            input_length: int) -> tuple[int, int] | None:
    if (not isinstance(values, (list, tuple)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values) or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(not _finite(value) for value in values):
        return None
    function_id = _integer(values[0], 0, 3)
    p = _integer(values[1], MIN_P, MAX_P)
    if function_id is None or p is None or input_length != 2:
        return None
    return function_id, p


def _integrate(function_id: int, p: int) -> float:
    h = 1.0 / float(1 << p)
    half_pi = PI / 2.0
    limit = 3 * (1 << p)
    total = 0.0
    for index in range(-limit, limit + 1):
        t = float(index) * h
        exp_t = math.exp(t)
        exp_minus_t = math.exp(-t)
        sinh_t = (exp_t - exp_minus_t) * 0.5
        cosh_t = (exp_t + exp_minus_t) * 0.5
        u = half_pi * sinh_t
        q = math.exp(-2.0 * abs(u))
        one_plus_q = 1.0 + q
        sech_squared = (4.0 * q) / (one_plus_q * one_plus_q)
        magnitude_x = (1.0 - q) / one_plus_q
        x = magnitude_x if u >= 0.0 else -magnitude_x
        jacobian = (half_pi * cosh_t) * sech_squared

        if function_id == 0:
            sample = 1.0
        elif function_id == 1:
            sample = x * x
        elif function_id == 2:
            sample = 1.0 / math.sqrt(sech_squared)
        elif u >= 0.0:
            sample = 1.0 / math.sqrt((2.0 * q) / one_plus_q)
        else:
            sample = 1.0 / math.sqrt(2.0 / one_plus_q)
        transformed = sample * jacobian
        total += h * transformed
    return total


def expected_output(values: Sequence[int | float], capacity: int | None = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    actual_length = (len(values) if input_length is None
                     and isinstance(values, (list, tuple)) else input_length)
    if actual_length is None:
        return INVALID_RESULT, ()
    decoded = _decode(values, input_is_null, actual_length)
    if decoded is None:
        return INVALID_RESULT, ()
    if type(output_is_null) is not bool or (capacity is not None and
            (type(capacity) is not int or capacity < 0)):
        return INVALID_RESULT, ()
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_ELEMENTS):
        return OUTPUT_ERROR, ()
    result = _integrate(*decoded)
    return (1, (result,)) if math.isfinite(result) else (INVALID_RESULT, ())
