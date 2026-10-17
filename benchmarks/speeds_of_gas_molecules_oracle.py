"""Oracle for the bounded gas-molecule speed formulas."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 4
MAX_TEMPERATURE_MK = 1_000_000
MAX_MOLAR_MASS_MICRO = 1_000_000_000
GAS_CONSTANT = 8.31446261815324
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    operation, temperature_mk, molar_mass_micro = values
    if (operation not in (0, 1)
            or not 0 <= temperature_mk <= MAX_TEMPERATURE_MK
            or not 1 <= molar_mass_micro <= MAX_MOLAR_MASS_MICRO):
        return INVALID_RESULT

    temperature = temperature_mk / 1000.0
    molar_mass = molar_mass_micro / 1_000_000.0
    if operation == 0:
        return math.pow((8.0 * GAS_CONSTANT * temperature) /
                        (math.pi * molar_mass), 0.5)
    return math.pow((2.0 * GAS_CONSTANT * temperature) / molar_mass, 0.5)
