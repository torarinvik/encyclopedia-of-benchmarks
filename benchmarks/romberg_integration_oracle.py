"""Primary binary64 oracle for the bounded Romberg integration profile."""

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
ABSOLUTE_TOLERANCE = 2e-5
RELATIVE_TOLERANCE = 1e-12


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _parse(values: Sequence[int | float], input_is_null: bool,
           input_length: int) -> tuple[int, float, float, int] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(not _finite_number(value) for value in values)
            or input_is_null):
        return None
    if input_length != len(values) or input_length != MAX_VALID_INPUT_LENGTH:
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
    return function_id, a_micro / 1_000_000.0, b_micro / 1_000_000.0, levels


def _function(function_id: int, x: float) -> float:
    if function_id == 0:
        return math.exp(x)
    if function_id == 1:
        return x * x * x * x * x
    if function_id == 2:
        return 1.0 / (1.0 + x * x)
    return math.cos(x)


def _romberg(function_id: int, a: float, b: float, levels: int) -> float:
    if a == b:
        return 0.0
    previous = [0.0] * (MAX_LEVELS + 1)
    previous[0] = (b - a) * (_function(function_id, a) + _function(function_id, b)) * 0.5
    for level in range(1, levels + 1):
        interval_count = 1 << level
        spacing = (b - a) / interval_count
        new_sum = 0.0
        for index in range(1, interval_count, 2):
            new_sum += _function(function_id, a + index * spacing)
        current = [0.0] * (MAX_LEVELS + 1)
        current[0] = previous[0] * 0.5 + spacing * new_sum
        factor = 4.0
        for order in range(1, level + 1):
            current[order] = current[order - 1] + (
                current[order - 1] - previous[order - 1]) / (factor - 1.0)
            factor *= 4.0
        previous = current
    return previous[levels]


def expected_output(
        values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False, input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    """Validate input then return the bottom-right Romberg tableau estimate."""
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
    result = _romberg(*parsed)
    return (1, (result,)) if math.isfinite(result) else (INVALID_RESULT, ())
