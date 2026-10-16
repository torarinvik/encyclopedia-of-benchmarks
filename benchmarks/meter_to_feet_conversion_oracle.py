"""Reference the two conversions exported by MeterToFeetConversion.js."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_MILLIUNITS = 1_000_000_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    operation, milliunits = values
    if operation not in (0, 1) or not -MAX_INPUT_MILLIUNITS <= milliunits <= MAX_INPUT_MILLIUNITS:
        return INVALID_RESULT
    value = milliunits / 1000.0
    if operation == 0:
        return value * 0.3048
    return value / 0.3048
