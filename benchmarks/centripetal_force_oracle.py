"""Independent bounded oracle for the centripetal-force formula."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_MASS = 1_000
MAX_ABSOLUTE_VELOCITY = 1_000
MAX_RADIUS = 1_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return (mass * velocity squared) / radius in source operation order."""
    if (not isinstance(values, (list, tuple)) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    mass, velocity, radius = values
    if (not 0 <= mass <= MAX_MASS
            or not -MAX_ABSOLUTE_VELOCITY <= velocity <= MAX_ABSOLUTE_VELOCITY
            or not 1 <= radius <= MAX_RADIUS):
        return INVALID_RESULT
    return float(mass * velocity * velocity) / radius
