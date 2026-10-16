"""Independent oracle for the bounded Rust speed-conversion contract."""

from __future__ import annotations

import math

SCALE = 1_000_000
MAX_SPEED_MICRO = 1_000_000_000_000_000
MAX_ROUNDED_MILLI = 1 << 53
INVALID_RESULT = -1e300

# These match the pinned source's `as_kmh_multiplier` and `kmh_multiplier`.
TO_KMH = (1.0, 3.6, 1.609344, 1.852, 1.09728, 1225.08, 1_079_252_848.8)
FROM_KMH = (1.0, 0.277777778, 0.621371192, 0.539956803,
            0.911344415, 0.000816164, 9.265669311e-10)


def expected_result(values: list[int]) -> float:
    """Return the selected converted speed rounded as Rust f64::round does."""
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    speed_micro, from_unit, to_unit = values
    if not -MAX_SPEED_MICRO <= speed_micro <= MAX_SPEED_MICRO:
        return INVALID_RESULT
    if not 0 <= from_unit < len(TO_KMH) or not 0 <= to_unit < len(FROM_KMH):
        return INVALID_RESULT

    speed = speed_micro / SCALE
    kmh = speed * TO_KMH[from_unit]
    result = kmh * FROM_KMH[to_unit]
    scaled = result * 1000.0
    if not math.isfinite(scaled) or abs(scaled) > MAX_ROUNDED_MILLI:
        return INVALID_RESULT

    magnitude = abs(scaled)
    rounded_milli = math.floor(magnitude)
    if magnitude - rounded_milli >= 0.5:
        rounded_milli += 1
    rounded = float(rounded_milli) / 1000.0
    return math.copysign(rounded, result)
