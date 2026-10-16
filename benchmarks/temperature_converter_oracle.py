"""Independent oracle for the pinned Java TemperatureConverter formulas."""

from __future__ import annotations

SCALE = 1_000_000
MAX_ABS_TEMPERATURE_MICRO = 1_000_000_000_000
MAX_INPUT_LENGTH = 3  # admit one extra packed value for malformed-input coverage
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    operation, temperature_micro = values
    if (operation < 0 or operation > 5
            or temperature_micro < -MAX_ABS_TEMPERATURE_MICRO
            or temperature_micro > MAX_ABS_TEMPERATURE_MICRO):
        return INVALID_RESULT

    temperature = temperature_micro / SCALE
    if operation == 0:  # celsiusToFahrenheit
        return temperature * 9.0 / 5.0 + 32.0
    if operation == 1:  # celsiusToKelvin
        return temperature + 273.15
    if operation == 2:  # fahrenheitToCelsius
        return (temperature - 32.0) * 5.0 / 9.0
    if operation == 3:  # fahrenheitToKelvin
        return (temperature - 32.0) * 5.0 / 9.0 + 273.15
    if operation == 4:  # kelvinToCelsius
        return temperature - 273.15
    # operation == 5: kelvinToFahrenheit
    return (temperature - 273.15) * 9.0 / 5.0 + 32.0
