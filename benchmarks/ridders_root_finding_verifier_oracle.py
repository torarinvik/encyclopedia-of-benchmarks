"""Independent high-precision bisection oracle for Ridders' bounded profile."""

from __future__ import annotations

import math
from collections.abc import Sequence
from decimal import Decimal, localcontext

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_ENDPOINT_MILLI = -3000
MAX_ENDPOINT_MILLI = 3000
MIN_TOLERANCE_MICRO = 1
MAX_TOLERANCE_MICRO = 1000
MIN_ITERATIONS = 24
MAX_ITERATIONS = 32
MAX_VALID_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_OUTPUT_ELEMENTS = 1


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _valid(values: Sequence[int | float], input_is_null: bool,
           input_length: int) -> tuple[int, Decimal, Decimal] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH or input_is_null
            or any(not _finite_number(value) for value in values)):
        return None
    if input_length != len(values) or len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    fields: list[int] = []
    for value in values:
        numeric = float(value)
        if not numeric.is_integer():
            return None
        fields.append(int(numeric))
    function_id, a, b, tolerance, iterations = fields
    if (function_id not in (0, 1, 2, 3)
            or not MIN_ENDPOINT_MILLI <= a <= MAX_ENDPOINT_MILLI
            or not MIN_ENDPOINT_MILLI <= b <= MAX_ENDPOINT_MILLI or a >= b
            or not MIN_TOLERANCE_MICRO <= tolerance <= MAX_TOLERANCE_MICRO
            or not MIN_ITERATIONS <= iterations <= MAX_ITERATIONS):
        return None
    with localcontext() as context:
        context.prec = 80
        left = Decimal(a) / Decimal(1000)
        right = Decimal(b) / Decimal(1000)
        f_left = _poly(function_id, left)
        f_right = _poly(function_id, right)
        if f_left != 0 and f_right != 0 and ((f_left < 0) == (f_right < 0)):
            return None
        return function_id, left, right


def _poly(function_id: int, x: Decimal) -> Decimal:
    if function_id == 0:
        return x * x - Decimal(2)
    if function_id == 1:
        return x * x * x - Decimal(2)
    if function_id == 2:
        return x * x * x + x - Decimal(1)
    return x


def _root(function_id: int, left: Decimal, right: Decimal) -> float:
    with localcontext() as context:
        context.prec = 80
        f_left = _poly(function_id, left)
        f_right = _poly(function_id, right)
        if f_left == 0:
            return float(left)
        if f_right == 0:
            return float(right)
        for _ in range(240):
            middle = (left + right) / Decimal(2)
            f_middle = _poly(function_id, middle)
            if f_middle == 0:
                return float(middle)
            if (f_left < 0) != (f_middle < 0):
                right, f_right = middle, f_middle
            else:
                left, f_left = middle, f_middle
        return float((left + right) / Decimal(2))


def expected_output(
        values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False, input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _valid(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    function_id, left, right = parsed
    return 1, (_root(function_id, left, right),)
