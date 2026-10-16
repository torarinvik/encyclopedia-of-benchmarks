"""Reference the bounded terminal-velocity formula."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 4
MIN_INPUT_VALUE = 1
MAX_INPUT_VALUE = 1_000
GRAVITY_METERS_PER_SECOND_SQUARED = 9.80665


def expected_result(values: list[int]) -> float:
    """Decode `[mass, density, area, drag_coefficient]`."""
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    mass, density, area, drag_coefficient = values
    if any(not MIN_INPUT_VALUE <= value <= MAX_INPUT_VALUE for value in values):
        return INVALID_RESULT
    return ((2 * mass * GRAVITY_METERS_PER_SECOND_SQUARED)
            / (density * area * drag_coefficient)) ** 0.5
