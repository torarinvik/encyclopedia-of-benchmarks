"""Independent oracle for the bounded Kullback-Leibler divergence benchmark."""

from collections.abc import Sequence
import math

MAX_COUNT = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_COUNT
SCALE = 1_000_000
INVALID_RESULT = -1e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> float:
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    count = values[0]
    if not 1 <= count <= MAX_COUNT or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    targets = values[1 : 1 + count]
    predictions = values[1 + count :]
    if any(not 0 <= value <= SCALE for value in targets + predictions):
        return INVALID_RESULT
    if any(target > 0 and prediction == 0 for target, prediction in zip(targets, predictions)):
        return INVALID_RESULT

    total = 0.0
    for target_scaled, prediction_scaled in zip(targets, predictions):
        if target_scaled == 0:
            continue
        target = target_scaled / SCALE
        prediction = prediction_scaled / SCALE
        total += target * math.log(target / prediction)
    return total
