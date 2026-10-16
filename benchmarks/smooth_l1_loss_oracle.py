"""Bounded fixed-point oracle for TheAlgorithms/Python smooth_l1_loss."""

from __future__ import annotations

MAX_COUNT = 256
MAX_PARSED_COUNT = 257
MAX_SAMPLE = 1_000_000
SCALE = 1_000_000
MAX_INPUT_LENGTH = 515
INVALID_RESULT = -1.0e300
BETA = 1.0


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    count = values[0]
    if (count < 0 or count > MAX_PARSED_COUNT
            or len(values) != 1 + 2 * count
            or count == 0 or count > MAX_COUNT):
        return INVALID_RESULT
    samples = values[1:]
    if any(abs(value) > MAX_SAMPLE for value in samples):
        return INVALID_RESULT

    total = 0.0
    for index in range(count):
        true_value = values[1 + index] / SCALE
        predicted_value = values[1 + count + index] / SCALE
        difference = true_value - predicted_value
        residual = abs(difference)
        if residual < BETA:
            total += 0.5 * residual * residual / BETA
        else:
            total += residual - 0.5 * BETA
    return total / count
