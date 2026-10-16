"""Independent bounded oracle for Archimedes' buoyant-force formula."""

from __future__ import annotations

GRAVITY_METERS_PER_SECOND_SQUARED = 9.80665
MAX_DENSITY = 1_000
MAX_VOLUME = 1_000
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return density * the pinned default gravity * displaced volume."""
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    density, volume = values
    if not 1 <= density <= MAX_DENSITY or not 1 <= volume <= MAX_VOLUME:
        return INVALID_RESULT
    return density * GRAVITY_METERS_PER_SECOND_SQUARED * volume
