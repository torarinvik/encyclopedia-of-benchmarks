"""Independent oracle for bounded, epsilon-smoothed KL divergence loss."""
from __future__ import annotations

import math

MAX_COUNT = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_COUNT
SCALE = 1_000_000
EPSILON = 1e-5
INVALID_RESULT = -1e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    actual_count, predicted_count = values[0], values[1]
    if not 0 <= actual_count <= MAX_COUNT or not 0 <= predicted_count <= MAX_COUNT:
        return INVALID_RESULT
    if len(values) != 2 + actual_count + predicted_count:
        return INVALID_RESULT
    actual = values[2 : 2 + actual_count]
    predicted = values[2 + actual_count :]
    if any(value < 0 or value > SCALE for value in (*actual, *predicted)):
        return INVALID_RESULT

    total = 0.0
    for actual_scaled, predicted_scaled in zip(actual, predicted):
        a = actual_scaled / SCALE
        p = predicted_scaled / SCALE
        adjusted_actual = a + EPSILON
        adjusted_predicted = p + EPSILON
        total += adjusted_actual * math.log(adjusted_actual / adjusted_predicted)
    return total
