"""Oracle for the common rounded PHP/Python/Ruby temperature conversions."""

from __future__ import annotations

SCALE = 1_000_000
MAX_ABS_TEMPERATURE_MICRO = 1_000_000_000_000
MAX_INPUT_LENGTH = 3  # permit one extra packed value for malformed-input coverage
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not -(1 << 63) <= value <= (1 << 63) - 1
                   for value in values)):
        return INVALID_RESULT
    operation, temperature_micro = values
    if (operation < 0 or operation > 4
            or not -MAX_ABS_TEMPERATURE_MICRO <= temperature_micro <= MAX_ABS_TEMPERATURE_MICRO):
        return INVALID_RESULT
    if operation == 0 and temperature_micro % 5_000_000 != 0:
        return INVALID_RESULT
    if operation == 1 and (temperature_micro - 32_000_000) % 9_000_000 != 0:
        return INVALID_RESULT
    if operation == 2 and temperature_micro % SCALE != 0:
        return INVALID_RESULT
    if operation == 3 and (temperature_micro - 273_150_000) % SCALE != 0:
        return INVALID_RESULT
    if operation == 4 and (temperature_micro - 273_150_000) % 5_000_000 != 0:
        return INVALID_RESULT

    temperature = temperature_micro / SCALE
    if operation == 0:  # C -> F: PHP uses one decimal; all lattice outputs are integers
        return round(temperature * 9.0 / 5.0 + 32.0, 2)
    if operation == 1:  # F -> C
        return round((temperature - 32.0) * 5.0 / 9.0, 2)
    if operation == 2:  # C -> K
        return round(temperature + 273.15, 2)
    if operation == 3:  # K -> C
        return round(temperature - 273.15, 2)
    # operation == 4: K -> F; Ruby's F -> K source is deliberately excluded
    return round((temperature - 273.15) * 9.0 / 5.0 + 32.0, 2)
