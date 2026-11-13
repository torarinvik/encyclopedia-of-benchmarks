"""Independent closed-form verifier for the bounded Romberg profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_ENDPOINT_MICRO = -1_000_000
MAX_ENDPOINT_MICRO = 1_000_000
MIN_LEVELS = 3
MAX_LEVELS = 8
MAX_VALID_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
MAX_OUTPUT_ELEMENTS = 1


def _finite(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _decode(values: Sequence[int | float], input_is_null: bool,
            input_length: int) -> tuple[int, float, float] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(not _finite(value) for value in values) or input_is_null):
        return None
    if input_length != len(values) or len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    fields: list[int] = []
    for value in values:
        numeric = float(value)
        if not numeric.is_integer():
            return None
        fields.append(int(numeric))
    function_id, a_micro, b_micro, levels = fields
    if (function_id not in (0, 1, 2, 3)
            or not MIN_ENDPOINT_MICRO <= a_micro <= MAX_ENDPOINT_MICRO
            or not MIN_ENDPOINT_MICRO <= b_micro <= MAX_ENDPOINT_MICRO
            or a_micro > b_micro or not MIN_LEVELS <= levels <= MAX_LEVELS):
        return None
    return function_id, a_micro / 1_000_000.0, b_micro / 1_000_000.0


def _antiderivative_difference(function_id: int, a: float, b: float) -> float:
    if function_id == 0:
        return math.exp(b) - math.exp(a)
    if function_id == 1:
        return (b ** 6 - a ** 6) / 6.0
    if function_id == 2:
        return math.atan(b) - math.atan(a)
    return math.sin(b) - math.sin(a)


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
    result = 0.0 if a == b else _antiderivative_difference(function_id, a, b)
    return (1, (result,)) if math.isfinite(result) else (INVALID_RESULT, ())
