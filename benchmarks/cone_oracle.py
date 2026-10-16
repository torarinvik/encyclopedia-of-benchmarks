"""Independent bounded oracle for the JavaScript cone benchmark."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_DIMENSION = 1_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the selected cone volume or surface area."""
    if (not isinstance(values, (list, tuple)) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    operation, radius, height = values
    if (operation not in (0, 1)
            or not 0 <= radius <= MAX_DIMENSION
            or not 0 <= height <= MAX_DIMENSION):
        return INVALID_RESULT

    base_area = math.pow(radius, 2) * math.pi
    if operation == 0:
        return (base_area * height * 1) / 3
    return base_area + math.pi * radius * math.sqrt(math.pow(radius, 2) + math.pow(height, 2))
