"""Bounded oracle for the pinned Julia rounded temperature conversions."""

from __future__ import annotations

import math

SCALE = 1_000_000
MAX_ABS_TEMPERATURE_MICRO = 1_000_000_000_000
MIN_NDIGITS = -6
MAX_NDIGITS = 6
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1e300


def _round_nearest_ties_even(value: float) -> float:
    lower = float(math.floor(value))
    fraction = value - lower
    if fraction < 0.5:
        return lower
    if fraction > 0.5:
        return lower + 1.0
    return lower if int(lower) % 2 == 0 else lower + 1.0


def _round_digits(value: float, digits: int) -> float:
    scale = 1.0
    for _ in range(abs(digits)):
        scale *= 10.0
    scaled = value * scale if digits >= 0 else value / scale
    rounded = _round_nearest_ties_even(scaled)
    return rounded / scale if digits >= 0 else rounded * scale


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return one bounded source-order conversion, or the invalid sentinel."""
    if (not isinstance(values, (list, tuple))
            or len(values) < 3
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    if len(values) != 3:
        return INVALID_RESULT
    operation, temperature_micro, digits = values
    if (operation < 0 or operation > 5
            or temperature_micro < -MAX_ABS_TEMPERATURE_MICRO
            or temperature_micro > MAX_ABS_TEMPERATURE_MICRO
            or digits < MIN_NDIGITS or digits > MAX_NDIGITS):
        return INVALID_RESULT

    temperature = temperature_micro / SCALE
    if operation == 0:
        result = temperature * 1.8 + 32.0
    elif operation == 1:
        result = temperature + 273.15
    elif operation == 2:
        result = (temperature - 32.0) * 5.0 / 9.0
    elif operation == 3:
        result = (temperature - 32.0) * 5.0 / 9.0 + 273.15
    elif operation == 4:
        result = temperature - 273.15
    else:
        result = (temperature - 273.15) * 1.8 + 32.0
    return _round_digits(result, digits)
