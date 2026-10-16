"""Independent bounded oracle for gravitational potential energy."""

from __future__ import annotations

GRAVITY_METERS_PER_SECOND_SQUARED = 9.80665
MAX_MASS = 1_000
MAX_HEIGHT = 1_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return mass * the pinned gravity constant * height."""
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    mass, height = values
    if not 0 <= mass <= MAX_MASS or not 0 <= height <= MAX_HEIGHT:
        return INVALID_RESULT
    return mass * GRAVITY_METERS_PER_SECOND_SQUARED * height
