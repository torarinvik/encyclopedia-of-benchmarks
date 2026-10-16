"""Reference the bounded root-mean-square molecular-speed formula."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 2
MAX_TEMPERATURE = 1_000
MIN_MOLAR_MASS = 1
MAX_MOLAR_MASS = 1_000
UNIVERSAL_GAS_CONSTANT = 8.3144598


def expected_result(values: list[int]) -> float:
    """Decode `[temperature, molar_mass]` and preserve the source expression."""
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    temperature, molar_mass = values
    if (not 0 <= temperature <= MAX_TEMPERATURE
            or not MIN_MOLAR_MASS <= molar_mass <= MAX_MOLAR_MASS):
        return INVALID_RESULT
    return (3 * UNIVERSAL_GAS_CONSTANT * temperature / molar_mass) ** 0.5
