"""Reference the bounded resonant-frequency formula."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 2
MIN_COMPONENT = 1
MAX_COMPONENT = 1_000


def expected_result(values: list[int]) -> float:
    """Decode `[inductance_henries, capacitance_farads]`."""
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    inductance, capacitance = values
    if (not MIN_COMPONENT <= inductance <= MAX_COMPONENT
            or not MIN_COMPONENT <= capacitance <= MAX_COMPONENT):
        return INVALID_RESULT
    return 1.0 / (2.0 * math.pi * math.sqrt(inductance * capacitance))
