"""Independent bounded oracle for the Reynolds number package."""

from __future__ import annotations

INVALID_RESULT = -1e300


def reynolds_number(values: list[int]) -> float:
    if (len(values) != 4
            or not 1 <= values[0] <= 1_000
            or not -1_000 <= values[1] <= 1_000
            or not 1 <= values[2] <= 1_000
            or not 1 <= values[3] <= 1_000):
        return INVALID_RESULT
    density, velocity, diameter, viscosity = values
    return (density * abs(velocity) * diameter) / viscosity
