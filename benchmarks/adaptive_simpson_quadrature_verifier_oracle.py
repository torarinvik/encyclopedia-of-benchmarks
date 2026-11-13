"""Independent closed-form verifier for the adaptive Simpson profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_ENDPOINT_MICRO = -2_000_000
MAX_ENDPOINT_MICRO = 2_000_000
MIN_TOLERANCE_EXPONENT = 7
MAX_TOLERANCE_EXPONENT = 8
MIN_DEPTH = 8
MAX_DEPTH = 12
MAX_VALID_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_OUTPUT_ELEMENTS = 1


def _decode(values: Sequence[int | float], input_is_null: bool,
            input_length: int) -> tuple[int, float, float] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) not in (int, float)
                   or not math.isfinite(float(value)) for value in values)
            or input_is_null):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH or input_length != len(values):
        return None
    fields: list[int] = []
    for value in values:
        numeric = float(value)
        if numeric != math.trunc(numeric):
            return None
        fields.append(int(numeric))
    function_id, a_micro, b_micro, exponent, depth = fields
    if (function_id not in (0, 1, 2)
            or not MIN_ENDPOINT_MICRO <= a_micro <= MAX_ENDPOINT_MICRO
            or not MIN_ENDPOINT_MICRO <= b_micro <= MAX_ENDPOINT_MICRO
            or a_micro > b_micro
            or not MIN_TOLERANCE_EXPONENT <= exponent <= MAX_TOLERANCE_EXPONENT
            or not MIN_DEPTH <= depth <= MAX_DEPTH):
        return None
    return function_id, a_micro / 1_000_000.0, b_micro / 1_000_000.0


def _primitive_difference(function_id: int, a: float, b: float) -> float:
    if function_id == 0:
        return (b ** 5 - a ** 5) / 5.0
    if function_id == 1:
        return math.cos(a) - math.cos(b)
    return math.atan(b) - math.atan(a)


def expected_output(
        values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False, input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    decoded = _decode(values, input_is_null, effective_length)
    if decoded is None:
        return INVALID_RESULT, ()
    if (type(capacity) is not int or capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    function_id, a, b = decoded
    result = _primitive_difference(function_id, a, b)
    return (1, (result,)) if math.isfinite(result) else (INVALID_RESULT, ())
