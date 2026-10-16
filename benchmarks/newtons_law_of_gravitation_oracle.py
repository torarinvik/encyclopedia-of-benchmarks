"""Reference the four bounded Newtonian gravitation calculations."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 4
MIN_SUPPLIED_VALUE = 1
MAX_SUPPLIED_VALUE = 1_000
GRAVITATIONAL_CONSTANT = 6.6743e-11


def expected_result(values: list[int]) -> float:
    """Decode `[missing_parameter_index, remaining canonical values...]`."""
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    selector, *supplied = values
    if (selector not in (0, 1, 2, 3)
            or any(not MIN_SUPPLIED_VALUE <= value <= MAX_SUPPLIED_VALUE
                   for value in supplied)):
        return INVALID_RESULT

    if selector == 0:
        mass_1, mass_2, distance = supplied
        return GRAVITATIONAL_CONSTANT * mass_1 * mass_2 / distance**2
    if selector == 1:
        force, mass_2, distance = supplied
        return force * distance**2 / (GRAVITATIONAL_CONSTANT * mass_2)
    if selector == 2:
        force, mass_1, distance = supplied
        return force * distance**2 / (GRAVITATIONAL_CONSTANT * mass_1)

    force, mass_1, mass_2 = supplied
    return (GRAVITATIONAL_CONSTANT * mass_1 * mass_2 / force) ** 0.5
