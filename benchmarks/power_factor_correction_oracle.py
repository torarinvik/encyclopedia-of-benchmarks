"""Reference bounded shunt power-factor correction calculations."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != 6
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    operation, voltage, frequency, real_power, current_units, expected_units = values
    if (operation not in (0, 1) or not 1 <= voltage <= 1000
            or not 1 <= frequency <= 1000 or not -1_000_000 <= real_power <= 1_000_000
            or not -10_000 <= current_units <= 10_000
            or not -10_000 <= expected_units <= 10_000
            or current_units == 0 or expected_units == 0):
        return INVALID_RESULT
    if operation == 1 and (current_units == expected_units or real_power == 0):
        return INVALID_RESULT

    current = current_units / 10_000.0
    expected = expected_units / 10_000.0
    current_q = (real_power / current) * math.sin(math.acos(current))
    expected_q = (real_power / expected) * math.sin(math.acos(expected))
    change_q = current_q - expected_q
    if operation == 0:
        return change_q / (2 * math.pi * frequency * (voltage**2))
    return (voltage**2) / (2 * math.pi * frequency * change_q)
