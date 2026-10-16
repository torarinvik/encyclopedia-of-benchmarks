"""Independent oracle for the bounded Java ProjectileMotion calculation."""

from __future__ import annotations

import math


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if not isinstance(values, (list, tuple)) or len(values) != 4:
        return None
    if any(type(value) not in (int, float) for value in values):
        return None
    velocity, angle_degrees, height, gravity = (float(value) for value in values)
    if any(not math.isfinite(value) for value in (velocity, angle_degrees, height, gravity)):
        return None
    if not 0.0 <= velocity <= 1000.0:
        return None
    if not -180.0 <= angle_degrees <= 180.0:
        return None
    if not 0.0 <= height <= 1000.0:
        return None
    if not 0.1 <= gravity <= 20.0:
        return None

    angle_radians = angle_degrees / 180.0 * math.pi
    initial_vertical_velocity = velocity * math.sin(angle_radians)
    initial_horizontal_velocity = velocity * math.cos(angle_radians)
    time_of_flight = (
        initial_vertical_velocity
        + math.sqrt(
            initial_vertical_velocity * initial_vertical_velocity
            + 2.0 * gravity * height
        )
    ) / gravity
    if initial_vertical_velocity > 0.0:
        height_gained = (
            initial_vertical_velocity * initial_vertical_velocity / (2.0 * gravity)
        )
        maximum_height = height + height_gained
    else:
        maximum_height = height
    horizontal_range = initial_horizontal_velocity * time_of_flight
    return [time_of_flight, horizontal_range, maximum_height]
