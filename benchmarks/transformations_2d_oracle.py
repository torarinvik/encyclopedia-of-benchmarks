"""Oracle for the bounded 2D transformation matrix component benchmark."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 4  # admit one trailing value for malformed-input coverage
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    operation, parameter_micro, component = values
    if not 0 <= operation <= 3 or not 0 <= component <= 3:
        return INVALID_RESULT

    if operation == 0:
        if not -1_000_000 <= parameter_micro <= 1_000_000:
            return INVALID_RESULT
        factor = parameter_micro / 1_000_000.0
        matrix = [factor, factor * 0.0, factor * 0.0, factor]
    else:
        if not -6_283_185 <= parameter_micro <= 6_283_185:
            return INVALID_RESULT
        angle = parameter_micro / 1_000_000.0
        c = math.cos(angle)
        s = math.sin(angle)
        if operation == 1:
            matrix = [c, -s, s, c]
        elif operation == 2:
            cs = c * s
            matrix = [c * c, cs, cs, s * s]
        else:
            cs = c * s
            matrix = [2 * c - 1, 2 * cs, 2 * cs, 2 * s - 1]
    return matrix[component]
