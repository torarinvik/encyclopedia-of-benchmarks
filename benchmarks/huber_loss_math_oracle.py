"""Oracle for the pinned Rust summed Huber-like loss on a bounded fixed-point domain."""

from __future__ import annotations

SCALE = 1_000_000
MAX_ARRAY_LENGTH = 64
MAX_PARSED_ARRAY_LENGTH = 65
MAX_SAMPLE = 1_000_000_000
MAX_DELTA = 1_000_000_000
MAX_INPUT_LENGTH = 3 + 2 * MAX_PARSED_ARRAY_LENGTH
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    delta_value, actual_count, predicted_count = values[:3]
    if not 0 <= delta_value <= MAX_DELTA:
        return INVALID_RESULT
    if not (0 <= actual_count <= MAX_PARSED_ARRAY_LENGTH
            and 0 <= predicted_count <= MAX_PARSED_ARRAY_LENGTH):
        return INVALID_RESULT
    if len(values) != 3 + actual_count + predicted_count:
        return INVALID_RESULT
    if actual_count > MAX_ARRAY_LENGTH or predicted_count > MAX_ARRAY_LENGTH:
        return INVALID_RESULT
    actual = values[3:3 + actual_count]
    predicted = values[3 + actual_count:]
    if any(abs(value) > MAX_SAMPLE for value in (*actual, *predicted)):
        return INVALID_RESULT

    delta = delta_value / SCALE
    total = 0.0
    for actual_value, predicted_value in zip(actual, predicted):
        difference = actual_value / SCALE - predicted_value / SCALE
        residual = abs(difference)
        if residual <= delta:
            total += 0.5 * difference**2
        else:
            # Preserve the pinned source's linear term exactly: it subtracts delta/2.
            total += delta * residual - 0.5 * delta
    return total
