"""Independent oracle for bounded categorical cross entropy."""

from __future__ import annotations

import math

MAX_BATCH = 64
MAX_CLASSES = 16
MAX_INPUT_LENGTH = 2 + 2 * MAX_BATCH * MAX_CLASSES
MAX_PROBABILITY = 1_000_000
EPSILON = 1e-15
INVALID_RESULT = -1e300
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def _decode(values: list[int] | tuple[int, ...]):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return None
    batch, classes = values[:2]
    if not 1 <= batch <= MAX_BATCH or not 2 <= classes <= MAX_CLASSES:
        return None
    cells = batch * classes
    if len(values) != 2 + 2 * cells:
        return None
    labels = values[2:2 + cells]
    probabilities = values[2 + cells:]
    for row in range(batch):
        start = row * classes
        label_row = labels[start:start + classes]
        probability_row = probabilities[start:start + classes]
        if any(label not in (0, 1) for label in label_row) or sum(label_row) != 1:
            return None
        if any(probability < 0 or probability > MAX_PROBABILITY for probability in probability_row):
            return None
        if sum(probability_row) != MAX_PROBABILITY:
            return None
    return batch, classes, labels, probabilities


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT
    _, _, labels, probabilities = decoded
    total = 0.0
    for label, scaled_probability in zip(labels, probabilities, strict=True):
        probability = min(1.0, max(EPSILON, scaled_probability / MAX_PROBABILITY))
        total -= label * math.log(probability)
    return total
