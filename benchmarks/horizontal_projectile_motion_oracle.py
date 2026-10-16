"""Oracle for the pinned horizontal-projectile formulas and byte encoding."""

from __future__ import annotations

import math
import struct

INVALID_RESULT = -1
CAPACITY_ERROR_RESULT = -2
MAX_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3  # Include the first rejected length for validation.
MAX_VELOCITY_MILLI = 100_000
MIN_ANGLE_MILLIDEGREES = 1_000
MAX_ANGLE_MILLIDEGREES = 90_000
OUTPUT_BYTES = 24
GRAVITY = 9.80665
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _to_cents(value: float) -> float:
    """Apply Python's source rounding, then return its binary64 value."""
    return round(value, 2)


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the source-ordered distance, height, and flight-time vector."""
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    velocity_milli, angle_millidegrees = values
    if (not 0 <= velocity_milli <= MAX_VELOCITY_MILLI
            or not MIN_ANGLE_MILLIDEGREES <= angle_millidegrees <= MAX_ANGLE_MILLIDEGREES):
        return INVALID_RESULT, b""

    velocity = velocity_milli / 1_000.0
    angle = angle_millidegrees / 1_000.0
    distance = _to_cents(velocity**2 * math.sin(math.radians(2 * angle)) / GRAVITY)
    sine = math.sin(math.radians(angle))
    height = _to_cents(velocity**2 * sine**2 / (2 * GRAVITY))
    flight_time = _to_cents(2 * velocity * sine / GRAVITY)
    return OUTPUT_BYTES, struct.pack("<ddd", distance, height, flight_time)
