"""Independent oracle for bounded Kendall tau-b rank correlation."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
MAX_OBSERVATIONS = 128
MAX_ABS_VALUE = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_OBSERVATIONS
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def expected_result(values: tuple[int, ...] | list[int]) -> float:
    if (not isinstance(values, (tuple, list)) or len(values) < 1
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    count = values[0]
    if not 2 <= count <= MAX_OBSERVATIONS or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    x_values = values[1:1 + count]
    y_values = values[1 + count:]
    if any(abs(value) > MAX_ABS_VALUE for value in x_values + y_values):
        return INVALID_RESULT

    concordant = discordant = ties_x = ties_y = 0
    for i in range(count):
        for j in range(i + 1, count):
            dx = (x_values[i] > x_values[j]) - (x_values[i] < x_values[j])
            dy = (y_values[i] > y_values[j]) - (y_values[i] < y_values[j])
            ties_x += dx == 0
            ties_y += dy == 0
            if dx * dy > 0:
                concordant += 1
            elif dx * dy < 0:
                discordant += 1
    denominator = math.sqrt((count * (count - 1) / 2 - ties_x)
                            * (count * (count - 1) / 2 - ties_y))
    if denominator == 0.0:
        return INVALID_RESULT
    return (concordant - discordant) / denominator
