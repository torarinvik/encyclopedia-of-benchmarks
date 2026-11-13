"""Primary binary64 oracle for the bounded Dormand–Prince 5(4) profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
NUMERICAL_FAILURE = -3
MIN_Y0_MILLI = -1000
MAX_Y0_MILLI = 1000
MIN_X_MILLI = -1000
MAX_X_MILLI = 1000
MIN_TOLERANCE_EXPONENT = 8
MAX_TOLERANCE_EXPONENT = 9
MIN_ATTEMPTS = 64
MAX_ATTEMPTS = 128
MAX_VALID_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7
MAX_OUTPUT_ELEMENTS = 1
ABSOLUTE_TOLERANCE = 2e-7
RELATIVE_TOLERANCE = 2e-7
WORKSPACE_BYTES = 8
INPUT_SCALE = 1000
MAX_STEP = 0.25


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _decode(values: Sequence[int | float], input_is_null: bool,
            input_length: int) -> tuple[int, float, float, float, int] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH or input_is_null
            or any(not _finite_number(value) for value in values)):
        return None
    if input_length != len(values) or input_length != MAX_VALID_INPUT_LENGTH:
        return None
    fields: list[int] = []
    for value in values:
        numeric = float(value)
        if not numeric.is_integer():
            return None
        fields.append(int(numeric))
    function_id, y0_milli, x0_milli, x_end_milli, tolerance_exponent, max_attempts = fields
    if (function_id not in (0, 1, 2, 3)
            or not MIN_Y0_MILLI <= y0_milli <= MAX_Y0_MILLI
            or not MIN_X_MILLI <= x0_milli <= MAX_X_MILLI
            or not MIN_X_MILLI <= x_end_milli <= MAX_X_MILLI
            or x_end_milli <= x0_milli
            or not MIN_TOLERANCE_EXPONENT <= tolerance_exponent <= MAX_TOLERANCE_EXPONENT
            or not MIN_ATTEMPTS <= max_attempts <= MAX_ATTEMPTS):
        return None
    return (function_id, y0_milli / INPUT_SCALE, x0_milli / INPUT_SCALE,
            x_end_milli / INPUT_SCALE, tolerance_exponent)


def _rhs(function_id: int, x: float, y: float) -> float:
    if function_id == 0:
        return y
    if function_id == 1:
        return x + y
    if function_id == 2:
        return math.sin(x)
    return 1.0


def _trial(function_id: int, x: float, y: float, h: float,
           k1: float) -> tuple[float, float, float] | None:
    """Return fifth-order state, embedded error estimate, and FSAL stage."""
    k2 = _rhs(function_id, x + h * (1.0 / 5.0), y + h * ((1.0 / 5.0) * k1))
    k3 = _rhs(function_id, x + h * (3.0 / 10.0),
              y + h * ((3.0 / 40.0) * k1 + (9.0 / 40.0) * k2))
    k4 = _rhs(function_id, x + h * (4.0 / 5.0),
              y + h * ((44.0 / 45.0) * k1 - (56.0 / 15.0) * k2 + (32.0 / 9.0) * k3))
    k5 = _rhs(function_id, x + h * (8.0 / 9.0),
              y + h * ((19372.0 / 6561.0) * k1 - (25360.0 / 2187.0) * k2
                       + (64448.0 / 6561.0) * k3 - (212.0 / 729.0) * k4))
    k6 = _rhs(function_id, x + h,
              y + h * ((9017.0 / 3168.0) * k1 - (355.0 / 33.0) * k2
                       + (46732.0 / 5247.0) * k3 + (49.0 / 176.0) * k4
                       - (5103.0 / 18656.0) * k5))
    y5 = y + h * ((35.0 / 384.0) * k1 + (500.0 / 1113.0) * k3
                  + (125.0 / 192.0) * k4 - (2187.0 / 6784.0) * k5
                  + (11.0 / 84.0) * k6)
    k7 = _rhs(function_id, x + h, y5)
    error = h * ((71.0 / 57600.0) * k1 - (71.0 / 16695.0) * k3
                 + (71.0 / 1920.0) * k4 - (17253.0 / 339200.0) * k5
                 + (22.0 / 525.0) * k6 - (1.0 / 40.0) * k7)
    if not all(math.isfinite(value) for value in (y5, error, k7)):
        return None
    return y5, error, k7


def _integrate(function_id: int, y0: float, x0: float, x_end: float,
               tolerance_exponent: int, max_attempts: int) -> tuple[int, float | None]:
    tolerance = 10.0 ** (-tolerance_exponent)
    x = x0
    y = y0
    h = min((x_end - x0) / 4.0, MAX_STEP)
    k1 = _rhs(function_id, x, y)
    for _ in range(max_attempts):
        remaining = x_end - x
        if remaining <= 0.0:
            return 1, y
        step = min(h, MAX_STEP, remaining)
        if step <= 0.0 or x + step == x:
            return NUMERICAL_FAILURE, None
        trial = _trial(function_id, x, y, step, k1)
        if trial is None:
            return NUMERICAL_FAILURE, None
        y5, error, k7 = trial
        scale = tolerance * (1.0 + max(abs(y), abs(y5)))
        error_norm = abs(error) / scale
        if not math.isfinite(error_norm):
            return NUMERICAL_FAILURE, None
        accepted = error_norm <= 1.0
        if accepted:
            if step == remaining:
                x = x_end
            else:
                x += step
            y = y5
            k1 = k7
            if x >= x_end:
                return (1, y) if math.isfinite(y) else (NUMERICAL_FAILURE, None)
        factor = 5.0 if error_norm == 0.0 else 0.9 * error_norm ** (-0.2)
        factor = min(5.0, max(0.2, factor))
        h = step * factor
    return NUMERICAL_FAILURE, None


def expected_output(
        values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False, input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _decode(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    function_id, y0, x0, x_end, exponent = parsed
    max_attempts = int(float(values[5]))
    status, result = _integrate(function_id, y0, x0, x_end, exponent, max_attempts)
    if status != 1 or result is None or not math.isfinite(result):
        return status if status != 1 else NUMERICAL_FAILURE, ()
    return 1, (result,)
