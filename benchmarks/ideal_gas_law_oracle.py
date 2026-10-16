"""Reference the four bounded ideal-gas calculations."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MIN_ARGUMENT = 0
MAX_ARGUMENT = 1_000
UNIVERSAL_GAS_CONSTANT = 8.314462


def expected_result(values: list[int]) -> float:
    """Decode `[operation, arg1, arg2, arg3]` in the source argument order."""
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    operation, arg1, arg2, arg3 = values
    if (operation not in (0, 1, 2, 3)
            or any(not MIN_ARGUMENT <= value <= MAX_ARGUMENT
                   for value in (arg1, arg2, arg3))):
        return INVALID_RESULT

    if operation == 0:
        moles, kelvin, volume = arg1, arg2, arg3
        if volume == 0:
            return INVALID_RESULT
        return moles * kelvin * UNIVERSAL_GAS_CONSTANT / volume
    if operation == 1:
        moles, kelvin, pressure = arg1, arg2, arg3
        if pressure == 0:
            return INVALID_RESULT
        return moles * kelvin * UNIVERSAL_GAS_CONSTANT / pressure
    if operation == 2:
        moles, volume, pressure = arg1, arg2, arg3
        if moles == 0:
            return INVALID_RESULT
        return pressure * volume / (moles * UNIVERSAL_GAS_CONSTANT)

    kelvin, volume, pressure = arg1, arg2, arg3
    if kelvin == 0:
        return INVALID_RESULT
    return pressure * volume / (kelvin * UNIVERSAL_GAS_CONSTANT)
