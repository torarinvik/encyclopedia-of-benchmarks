"""High-precision trigonometric reference for circular mean direction."""

from __future__ import annotations

import math
from decimal import Decimal, ROUND_FLOOR, localcontext
from typing import Sequence

MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = 66
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_PI = Decimal.from_float(math.pi)
_TAU = Decimal.from_float(2.0 * math.pi)
_CUTOFF_SCALE = Decimal(2) ** -28


def _finite_float(value: object) -> bool:
    if type(value) is int:
        return abs(value) <= 8 * math.ceil(math.pi) + 1
    return type(value) is float and math.isfinite(value)


def _series_sine_cosine(value: Decimal) -> tuple[Decimal, Decimal]:
    square = value * value
    sine = sine_term = value
    cosine = cosine_term = Decimal(1)
    for index in range(1, 100):
        sine_term *= -square / Decimal((2 * index) * (2 * index + 1))
        cosine_term *= -square / Decimal((2 * index - 1) * (2 * index))
        sine += sine_term
        cosine += cosine_term
        if abs(sine_term) < Decimal("1e-78") and abs(cosine_term) < Decimal("1e-78"):
            break
    return sine, cosine


def _decimal_wrap(value: Decimal) -> Decimal:
    turns = ((value + _PI) / _TAU).to_integral_value(rounding=ROUND_FLOOR)
    wrapped = value - turns * _TAU
    if wrapped >= _PI:
        wrapped -= _TAU
    if wrapped < -_PI:
        wrapped += _TAU
    return wrapped


def _float_wrap(value: float) -> float:
    pi = math.pi
    tau = 2.0 * pi
    result = value - math.floor((value + pi) / tau) * tau
    if result >= pi:
        result -= tau
    if result < -pi:
        result += tau
    return result


def expected_output(values: Sequence[float], output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    if (input_is_null or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and
            (type(input_length) is not int or input_length != len(values))):
        return INVALID_RESULT, []
    count_value = values[0]
    if (type(count_value) is int and not 1 <= count_value <= MAX_N):
        return INVALID_RESULT, []
    if (type(count_value) is float and (not math.isfinite(count_value)
            or not count_value.is_integer() or not 1.0 <= count_value <= float(MAX_N))):
        return INVALID_RESULT, []
    if (type(count_value) not in (int, float) or not 1 <= count_value <= MAX_N
            or len(values) != int(count_value) + 1):
        return INVALID_RESULT, []
    bound = 8.0 * math.pi
    if any(not _finite_float(angle) or abs(float(angle)) > bound for angle in values[1:]):
        return INVALID_RESULT, []

    count = int(count_value)
    with localcontext() as context:
        context.prec = 90
        sine_sum = Decimal(0)
        cosine_sum = Decimal(0)
        for raw_angle in values[1:]:
            angle = _decimal_wrap(Decimal.from_float(float(raw_angle)))
            sine, cosine = _series_sine_cosine(angle)
            sine_sum += sine
            cosine_sum += cosine
        resultant = (sine_sum * sine_sum + cosine_sum * cosine_sum).sqrt()
        if resultant <= Decimal(count) * _CUTOFF_SCALE:
            return INVALID_RESULT, []
        if output_is_null or (output_capacity is not None and
                              (type(output_capacity) is not int or output_capacity < 1)):
            return OUTPUT_ERROR, []
        direction = math.atan2(float(sine_sum), float(cosine_sum))
        return 1, [_float_wrap(direction)]
