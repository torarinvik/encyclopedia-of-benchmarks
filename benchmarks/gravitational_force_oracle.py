"""Independent oracle for TheAlgorithms Java Gravitation force-vector method."""
from __future__ import annotations

import math

GRAVITATIONAL_CONSTANT = 6.67430e-11


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or len(values) != 6
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None
    mass_1, x_1, y_1, mass_2, x_2, y_2 = map(float, values)
    if (abs(mass_1) > 1.0e12 or abs(mass_2) > 1.0e12
            or (mass_1 != 0.0 and abs(mass_1) < 1.0e-12)
            or (mass_2 != 0.0 and abs(mass_2) < 1.0e-12)
            or any(abs(position) > 1.0e6 for position in (x_1, y_1, x_2, y_2))):
        return None
    dx, dy = x_1 - x_2, y_1 - y_2
    distance_squared = dx * dx + dy * dy
    if distance_squared != 0.0 and distance_squared < 1.0e-12:
        return None
    if distance_squared == 0.0:
        return [0.0, 0.0]
    distance = math.sqrt(distance_squared)
    force_magnitude = GRAVITATIONAL_CONSTANT * mass_1 * mass_2 / distance_squared
    return [force_magnitude * (dx / distance), force_magnitude * (dy / distance)]
