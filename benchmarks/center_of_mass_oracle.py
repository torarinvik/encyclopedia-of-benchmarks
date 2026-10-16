"""Independent oracle for the bounded center-of-mass benchmark contract."""

from __future__ import annotations

SCALE = 1000
MAX_PARTICLES = 64
MAX_COORDINATE_UNITS = 1_000_000
MAX_MASS_UNITS = 1_000_000
INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 2 + 4 * MAX_PARTICLES


def expected_result(values: list[int]) -> float:
    """Return a rounded selected center coordinate, or the invalid sentinel."""
    if not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int for value in values):
        return INVALID_RESULT
    selector, particle_count = values[:2]
    if selector not in (0, 1, 2) or not 1 <= particle_count <= MAX_PARTICLES:
        return INVALID_RESULT
    if len(values) != 2 + 4 * particle_count:
        return INVALID_RESULT

    records = []
    for offset in range(2, len(values), 4):
        x_units, y_units, z_units, mass_units = values[offset : offset + 4]
        if any(not -MAX_COORDINATE_UNITS <= coordinate <= MAX_COORDINATE_UNITS
               for coordinate in (x_units, y_units, z_units)):
            return INVALID_RESULT
        if not 1 <= mass_units <= MAX_MASS_UNITS:
            return INVALID_RESULT
        records.append((x_units / SCALE, y_units / SCALE, z_units / SCALE, mass_units / SCALE))

    total_mass = sum(particle[3] for particle in records)
    weighted_coordinate = sum(particle[selector] * particle[3] for particle in records)
    return round(weighted_coordinate / total_mass, 2)
