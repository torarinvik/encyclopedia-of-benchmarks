"""Primary sequential-vector oracle for the circular mean direction ABI."""

from __future__ import annotations

import math
from typing import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 65
MAX_PARSEABLE_INPUT_LENGTH = 66
MAX_OUTPUT_ELEMENTS = 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _wrap(angle: float) -> float:
    pi = math.pi
    tau = 2.0 * pi
    wrapped = angle - math.floor((angle + pi) / tau) * tau
    if wrapped >= pi:
        wrapped -= tau
    if wrapped < -pi:
        wrapped += tau
    return wrapped


def _valid(values: Sequence[float], input_length: int | None,
           input_is_null: bool) -> bool:
    if input_is_null or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return False
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return False
    count = values[0]
    if type(count) is int:
        if not 1 <= count <= MAX_N:
            return False
    elif (type(count) is not float or not math.isfinite(count)
            or not count.is_integer() or not 1.0 <= count <= float(MAX_N)):
        return False
    if len(values) != int(count) + 1:
        return False
    bound = 8.0 * math.pi
    for angle in values[1:]:
        if type(angle) is int:
            if abs(angle) > bound:
                return False
        elif (type(angle) is not float or not math.isfinite(angle)
                or abs(angle) > bound):
            return False
    return True


def expected_output(values: Sequence[float], output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    """Return ABI status and output values without modifying output on errors."""
    if not _valid(values, input_length, input_is_null):
        return INVALID_RESULT, []

    count = int(values[0])
    sum_cos = sum_sin = 0.0
    correction_cos = correction_sin = 0.0
    for raw_angle in values[1:]:
        angle = _wrap(float(raw_angle))
        value_cos = math.cos(angle)
        adjusted_cos = value_cos - correction_cos
        next_cos = sum_cos + adjusted_cos
        correction_cos = (next_cos - sum_cos) - adjusted_cos
        sum_cos = next_cos

        value_sin = math.sin(angle)
        adjusted_sin = value_sin - correction_sin
        next_sin = sum_sin + adjusted_sin
        correction_sin = (next_sin - sum_sin) - adjusted_sin
        sum_sin = next_sin

    resultant = math.hypot(sum_cos, sum_sin)
    if not math.isfinite(resultant) or resultant <= count * (2.0 ** -28):
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < 1)):
        return OUTPUT_ERROR, []
    return 1, [_wrap(math.atan2(sum_sin, sum_cos))]
