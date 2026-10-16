"""Independent oracle for bounded binary cross entropy."""

from __future__ import annotations

import math

MAX_COUNT = 256
MAX_INPUT_LENGTH = 1 + 2 * MAX_COUNT
MAX_PROBABILITY = 1_000_000
EPSILON = 1e-15
INVALID_RESULT = -1e300
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    count = values[0]
    if not 1 <= count <= MAX_COUNT or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    labels = values[1:1 + count]
    probabilities = values[1 + count:]
    if any(label not in (0, 1) for label in labels):
        return INVALID_RESULT
    if any(probability < 0 or probability > MAX_PROBABILITY for probability in probabilities):
        return INVALID_RESULT
    total = 0.0
    for label, scaled_probability in zip(labels, probabilities, strict=True):
        probability = scaled_probability / MAX_PROBABILITY
        probability = min(1.0 - EPSILON, max(EPSILON, probability))
        total -= label * math.log(probability) + (1 - label) * math.log(1.0 - probability)
    return total / count
