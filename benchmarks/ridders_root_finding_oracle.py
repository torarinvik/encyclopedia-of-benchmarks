"""Primary binary64 oracle for the bounded Ridders root-finding profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
NUMERICAL_FAILURE = -3
MIN_ENDPOINT_MILLI = -3000
MAX_ENDPOINT_MILLI = 3000
MIN_TOLERANCE_MICRO = 1
MAX_TOLERANCE_MICRO = 1000
MIN_ITERATIONS = 24
MAX_ITERATIONS = 32
MAX_VALID_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_OUTPUT_ELEMENTS = 1
ABSOLUTE_TOLERANCE = 1.1e-3
RELATIVE_TOLERANCE = 1e-12


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
    function_id, left_milli, right_milli, tolerance_micro, iterations = fields
    if (function_id not in (0, 1, 2, 3)
            or not MIN_ENDPOINT_MILLI <= left_milli <= MAX_ENDPOINT_MILLI
            or not MIN_ENDPOINT_MILLI <= right_milli <= MAX_ENDPOINT_MILLI
            or left_milli >= right_milli
            or not MIN_TOLERANCE_MICRO <= tolerance_micro <= MAX_TOLERANCE_MICRO
            or not MIN_ITERATIONS <= iterations <= MAX_ITERATIONS):
        return None
    left = left_milli / 1000.0
    right = right_milli / 1000.0
    f_left = _function(function_id, left)
    f_right = _function(function_id, right)
    if f_left == 0.0 or f_right == 0.0:
        return function_id, left, right, tolerance_micro / 1_000_000.0, iterations
    if (f_left < 0.0) == (f_right < 0.0):
        return None
    return function_id, left, right, tolerance_micro / 1_000_000.0, iterations


def _function(function_id: int, x: float) -> float:
    if function_id == 0:
        return x * x - 2.0
    if function_id == 1:
        return x * x * x - 2.0
    if function_id == 2:
        return x * x * x + x - 1.0
    return x


def _solve(parsed: tuple[int, float, float, float, int]) -> tuple[int, float | None]:
    function_id, left, right, tolerance, iterations = parsed
    f_left = _function(function_id, left)
    f_right = _function(function_id, right)
    if f_left == 0.0:
        return 1, left
    if f_right == 0.0:
        return 1, right

    for _ in range(iterations):
        if right - left <= tolerance:
            return 1, (left + right) * 0.5
        middle = (left + right) * 0.5
        f_middle = _function(function_id, middle)
        if f_middle == 0.0:
            return 1, middle
        radicand = f_middle * f_middle - f_left * f_right
        if not math.isfinite(radicand) or radicand <= 0.0:
            return NUMERICAL_FAILURE, None
        denominator = math.sqrt(radicand)
        if denominator == 0.0 or not math.isfinite(denominator):
            return NUMERICAL_FAILURE, None
        direction = -1.0 if f_left < f_right else 1.0
        candidate = middle + (middle - left) * direction * f_middle / denominator
        if not math.isfinite(candidate) or not left < candidate < right:
            return NUMERICAL_FAILURE, None
        f_candidate = _function(function_id, candidate)
        if f_candidate == 0.0:
            return 1, candidate
        if (f_left < 0.0) != (f_candidate < 0.0):
            right, f_right = candidate, f_candidate
        else:
            left, f_left = candidate, f_candidate
        if right - left <= tolerance:
            return 1, (left + right) * 0.5
    return NUMERICAL_FAILURE, None


def expected_output(
        values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False, input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    """Apply input validation before output checks, then execute Ridders' updates."""
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _decode(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if (type(capacity) is not int or capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    result, root = _solve(parsed)
    if result != 1 or root is None or not math.isfinite(root):
        return result, ()
    return 1, (root,)


def expected_result(values: Sequence[int | float]) -> float | int:
    result, output = expected_output(values)
    return output[0] if result == 1 else result
