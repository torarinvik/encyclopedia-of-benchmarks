"""Independent oracle for TheAlgorithms Java circular-orbit speed method."""
from __future__ import annotations

import math

GRAVITATIONAL_CONSTANT = 6.67430e-11


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None
    mass, radius = map(float, values)
    if not 1.0e-12 <= mass <= 1.0e25 or not 1.0e-12 <= radius <= 1.0e12:
        return None
    return [math.sqrt(GRAVITATIONAL_CONSTANT * mass / radius)]
