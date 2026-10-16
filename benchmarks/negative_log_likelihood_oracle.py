"""Bounded oracle for the pinned Rust binary negative log-likelihood source."""
import math

INVALID_RESULT = -1e300
MAX_COUNT = 64
SCALE = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_COUNT


def expected_result(values: list[int]) -> float:
    if not values:
        return INVALID_RESULT
    count = values[0]
    if count < 1 or count > MAX_COUNT or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    actual = values[1:1 + count]
    predicted = values[1 + count:]
    if any(value < 0 or value > SCALE for value in actual):
        return INVALID_RESULT
    if any(value < 1 or value >= SCALE for value in predicted):
        return INVALID_RESULT
    total = 0.0
    for actual_scaled, predicted_scaled in zip(actual, predicted):
        actual_probability = actual_scaled / SCALE
        predicted_probability = predicted_scaled / SCALE
        total += (-actual_probability * math.log(predicted_probability)
                  - (1.0 - actual_probability) * math.log(1.0 - predicted_probability))
    return total / count
