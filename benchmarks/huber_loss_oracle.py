"""Oracle for a bounded fixed-point adaptation of TheAlgorithms/Rust Huber loss."""

from __future__ import annotations

MAX_PAIRS = 64
MAX_PARSED_PAIRS_PER_SIDE = 65
MAX_SAMPLE = 1_000_000_000  # fixed-point micro-units, or 1,000 physical units
MAX_DELTA = 1_000_000_000
SCALE = 1_000_000
MAX_INPUT_LENGTH = 3 + 2 * MAX_PARSED_PAIRS_PER_SIDE
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    delta_value, true_count, pred_count = values[:3]
    if not 0 <= delta_value <= MAX_DELTA:
        return INVALID_RESULT
    if not 0 <= true_count <= MAX_PARSED_PAIRS_PER_SIDE or not 0 <= pred_count <= MAX_PARSED_PAIRS_PER_SIDE:
        return INVALID_RESULT
    if len(values) != 3 + true_count + pred_count:
        return INVALID_RESULT
    if true_count != pred_count or pred_count == 0 or true_count > MAX_PAIRS:
        return INVALID_RESULT

    true_values = values[3:3 + true_count]
    predicted_values = values[3 + true_count:]
    if any(abs(value) > MAX_SAMPLE for value in (*true_values, *predicted_values)):
        return INVALID_RESULT

    delta = delta_value / SCALE
    total_loss = 0.0
    for true_value, predicted_value in zip(true_values, predicted_values):
        residual = abs(true_value / SCALE - predicted_value / SCALE)
        if residual <= delta:
            total_loss += 0.5 * residual**2
        else:
            total_loss += delta * residual - 0.5 * delta**2
    return total_loss / pred_count
