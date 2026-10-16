"""Independent bounded oracle for classical kinetic energy."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_MASS = 1_000
MAX_ABSOLUTE_VELOCITY = 1_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the pinned expression in its original multiplication order."""
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    mass, velocity = values
    if not 0 <= mass <= MAX_MASS or not -MAX_ABSOLUTE_VELOCITY <= velocity <= MAX_ABSOLUTE_VELOCITY:
        return INVALID_RESULT
    return 0.5 * mass * abs(velocity) * abs(velocity)
