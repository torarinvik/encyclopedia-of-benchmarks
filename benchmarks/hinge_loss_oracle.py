"""Independent bounded oracle for the Rust hinge-loss function."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_COUNT = 256
MAX_INPUT_LENGTH = 1 + 2 * MAX_COUNT
PREDICTION_SCALE = 1_000_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    count = values[0]
    if type(count) is not int or not 1 <= count <= MAX_COUNT or len(values) != 1 + 2 * count:
        return INVALID_RESULT

    labels = values[1:1 + count]
    predictions_scaled = values[1 + count:]
    if (any(label not in (-1, 1) for label in labels)
            or any(not -PREDICTION_SCALE <= score <= PREDICTION_SCALE
                   for score in predictions_scaled)):
        return INVALID_RESULT

    total = 0.0
    for label, score_scaled in zip(labels, predictions_scaled):
        prediction = score_scaled / PREDICTION_SCALE
        loss = 1.0 - label * prediction
        if loss > 0.0:
            total += loss
    return total / count
