"""Independent closed-form verifier for four bounded ODE right-hand sides."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_VALID_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7
MAX_OUTPUT_ELEMENTS = 1
ABSOLUTE_TOLERANCE = 2e-7
RELATIVE_TOLERANCE = 2e-7
WORKSPACE_BYTES = 8


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _decode(values: Sequence[int | float], input_is_null: bool,
            input_length: int) -> tuple[int, float, float, float] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH or input_is_null):
        return None
    if input_length != len(values) or input_length != MAX_VALID_INPUT_LENGTH:
        return None
    fields: list[int] = []
    for value in values:
        if not _finite_number(value):
            return None
        numeric = float(value)
        if not numeric.is_integer():
            return None
        fields.append(int(numeric))
    function_id, y0_milli, x0_milli, x_end_milli, tolerance_exponent, max_attempts = fields
    if (function_id not in (0, 1, 2, 3)
            or not -1000 <= y0_milli <= 1000
            or not -1000 <= x0_milli <= 1000
            or not -1000 <= x_end_milli <= 1000
            or x_end_milli <= x0_milli
            or not 8 <= tolerance_exponent <= 9
            or not 64 <= max_attempts <= 128):
        return None
    return function_id, y0_milli / 1000.0, x0_milli / 1000.0, x_end_milli / 1000.0


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
    function_id, y0, x0, x_end = parsed
    if function_id == 0:
        result = y0 * math.exp(x_end - x0)
    elif function_id == 1:
        result = math.exp(x_end - x0) * (y0 + x0 + 1.0) - x_end - 1.0
    elif function_id == 2:
        result = y0 + math.cos(x0) - math.cos(x_end)
    else:
        result = y0 + (x_end - x0)
    if not math.isfinite(result):
        return INVALID_RESULT, ()
    return 1, (result,)
