"""Independent oracle for the pinned Momentum recurrence with fixed parameters."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_LENGTH = 1
MAX_LENGTH = 64
MIN_VALUE = -1_000_000.0
MAX_VALUE = 1_000_000.0
LEARNING_RATE = 0.01
BETA = 0.9
ITERATIONS = 100


def expected_result(values: Sequence[float]) -> list[float] | None:
    """Return the final parameter vector, or None for an invalid ABI input."""
    if (not isinstance(values, (list, tuple)) or not MIN_LENGTH <= len(values) <= MAX_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None
    parameters = [float(value) for value in values]
    if any(value < MIN_VALUE or value > MAX_VALUE for value in parameters):
        return None

    velocity = [0.0] * len(parameters)
    for _ in range(ITERATIONS):
        gradient = [2.0 * value for value in parameters]
        for index in range(len(parameters)):
            velocity[index] = BETA * velocity[index] + gradient[index]
            parameters[index] -= LEARNING_RATE * velocity[index]
    return parameters
