"""Independent oracle for the bounded charging-inductor contract."""

from __future__ import annotations

import math

SCALE = 1_000_000
MAX_VOLTAGE_MICRO = 1_000_000_000_000
MIN_RESISTANCE_MICRO = 10_000
MAX_RESISTANCE_MICRO = 1_000_000_000_000_000
MAX_INDUCTANCE_MICRO = 1_000_000_000_000
MAX_TIME_MICRO = 1_000_000_000_000
MAX_EXPONENT = 10.0
INVALID_RESULT = -1e300


def expected_result(values: list[int]) -> float:
    """Return the source-rounded inductor current, or the invalid sentinel."""
    if (not isinstance(values, list) or len(values) != 4
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    voltage_micro, resistance_micro, inductance_micro, time_micro = values
    if not 1 <= voltage_micro <= MAX_VOLTAGE_MICRO:
        return INVALID_RESULT
    if not MIN_RESISTANCE_MICRO <= resistance_micro <= MAX_RESISTANCE_MICRO:
        return INVALID_RESULT
    if not 1 <= inductance_micro <= MAX_INDUCTANCE_MICRO:
        return INVALID_RESULT
    if not -MAX_TIME_MICRO <= time_micro <= MAX_TIME_MICRO:
        return INVALID_RESULT

    source_voltage = voltage_micro / SCALE
    resistance = resistance_micro / SCALE
    inductance = inductance_micro / SCALE
    time_sec = time_micro / SCALE
    exponent = (-time_sec * resistance) / inductance
    if exponent > MAX_EXPONENT:
        return INVALID_RESULT
    return round(source_voltage / resistance * (1.0 - math.exp(exponent)), 3)
