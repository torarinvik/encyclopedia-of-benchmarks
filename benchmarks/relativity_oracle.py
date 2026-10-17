"""Oracle for the bounded Java relativity formula benchmark."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 4  # admit one trailing value for malformed-input coverage
SPEED_OF_LIGHT = 299_792_458.0
SPEED_OF_LIGHT_MILLI = 299_792_458_000
MAX_LENGTH_TIME_MILLI = 1_000_000
INVALID_RESULT = -1.0e300


def _gamma(velocity: float) -> float:
    return 1.0 / math.sqrt(1.0 - velocity * velocity /
                           (SPEED_OF_LIGHT * SPEED_OF_LIGHT))


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    operation, arg1_milli, arg2_milli = values
    if operation == 0:
        if (not -SPEED_OF_LIGHT_MILLI < arg1_milli < SPEED_OF_LIGHT_MILLI
                or arg2_milli != 0):
            return INVALID_RESULT
        velocity = arg1_milli / 1000.0
        return _gamma(velocity)

    if operation in (1, 2):
        if (not 0 <= arg1_milli <= MAX_LENGTH_TIME_MILLI
                or not -SPEED_OF_LIGHT_MILLI < arg2_milli < SPEED_OF_LIGHT_MILLI):
            return INVALID_RESULT
        quantity = arg1_milli / 1000.0
        velocity = arg2_milli / 1000.0
        factor = _gamma(velocity)
        if operation == 1:
            return quantity / factor
        return quantity * factor

    if operation == 3:
        if (not -SPEED_OF_LIGHT_MILLI <= arg1_milli <= SPEED_OF_LIGHT_MILLI
                or not -SPEED_OF_LIGHT_MILLI < arg2_milli < SPEED_OF_LIGHT_MILLI):
            return INVALID_RESULT
        velocity_one = arg1_milli / 1000.0
        frame_velocity = arg2_milli / 1000.0
        return (velocity_one - frame_velocity) / (
            1.0 - velocity_one * frame_velocity /
            (SPEED_OF_LIGHT * SPEED_OF_LIGHT))

    return INVALID_RESULT
