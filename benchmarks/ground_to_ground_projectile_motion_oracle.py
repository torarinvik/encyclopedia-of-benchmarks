"""Oracle for the bounded ground-to-ground projectile motion contract."""

from __future__ import annotations

import math

SCALE = 1_000_000
MAX_SPEED = 1_000 * SCALE
MAX_ANGLE = 360 * SCALE
MIN_GRAVITY = SCALE // 1_000
MAX_GRAVITY = 100 * SCALE
MAX_TIME = 1_000 * SCALE
MAX_INPUT_LENGTH = 5
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if len(values) != 4:
        return INVALID_RESULT

    operation, speed_value, angle_value, auxiliary_value = values
    if operation not in (0, 1, 2):
        return INVALID_RESULT
    if not 0 <= speed_value <= MAX_SPEED or not -MAX_ANGLE <= angle_value <= MAX_ANGLE:
        return INVALID_RESULT

    if operation == 1:
        if not 0 <= auxiliary_value <= MAX_TIME:
            return INVALID_RESULT
    elif not MIN_GRAVITY <= auxiliary_value <= MAX_GRAVITY:
        return INVALID_RESULT

    speed = speed_value / SCALE
    angle = angle_value / SCALE
    radians = angle * (math.pi / 180.0)
    vertical_velocity = speed * math.sin(radians)

    if operation == 0:
        gravity = auxiliary_value / SCALE
        return 2.0 * vertical_velocity / gravity
    if operation == 1:
        time = auxiliary_value / SCALE
        horizontal_velocity = speed * math.cos(radians)
        return horizontal_velocity * time

    gravity = auxiliary_value / SCALE
    return math.pow(vertical_velocity, 2.0) / (2.0 * gravity)
