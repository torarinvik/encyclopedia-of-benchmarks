"""Oracle for bounded mini-batch gradient descent with explicit epoch orders."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_SAMPLES = 1
MAX_SAMPLES = 8
MIN_FEATURES = 1
MAX_FEATURES = 3
MIN_EPOCHS = 0
MAX_EPOCHS = 8
MAX_INPUT_LENGTH = 5 + MAX_SAMPLES * MAX_FEATURES + MAX_SAMPLES + MAX_SAMPLES * MAX_EPOCHS
MAX_OUTPUT_LENGTH = MAX_FEATURES + 1
INVALID_RESULT = -1


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def expected_result(values: Sequence[int | float] | None) -> list[float] | int:
    """Run the source update loop over supplied epoch permutations, or return -1."""
    if not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if not all(_finite_number(value) for value in values):
        return INVALID_RESULT
    if any(values[i] != int(values[i]) for i in range(4)):
        return INVALID_RESULT
    samples, features, batch_size, epochs = map(int, values[:4])
    learning_rate = float(values[4])
    if not MIN_SAMPLES <= samples <= MAX_SAMPLES:
        return INVALID_RESULT
    if not MIN_FEATURES <= features <= MAX_FEATURES:
        return INVALID_RESULT
    if not 1 <= batch_size <= samples or not MIN_EPOCHS <= epochs <= MAX_EPOCHS:
        return INVALID_RESULT
    if not 0.0 <= learning_rate <= 0.25:
        return INVALID_RESULT
    matrix_end = 5 + samples * features
    targets_end = matrix_end + samples
    if len(values) != targets_end + epochs * samples:
        return INVALID_RESULT
    matrix = [float(value) for value in values[5:matrix_end]]
    targets = [float(value) for value in values[matrix_end:targets_end]]
    if any(abs(value) > 10.0 for value in matrix) or any(abs(value) > 100.0 for value in targets):
        return INVALID_RESULT

    permutations: list[list[int]] = []
    offset = targets_end
    for _ in range(epochs):
        row: list[int] = []
        for value in values[offset:offset + samples]:
            if value != int(value) or not 0 <= value < samples:
                return INVALID_RESULT
            row.append(int(value))
        if sorted(row) != list(range(samples)):
            return INVALID_RESULT
        permutations.append(row)
        offset += samples

    weights = [0.0] * features
    bias = 0.0
    for order in permutations:
        for start in range(0, samples, batch_size):
            batch = order[start:start + batch_size]
            errors: list[float] = []
            for sample in batch:
                prediction = 0.0
                for feature in range(features):
                    prediction += matrix[sample * features + feature] * weights[feature]
                prediction += bias
                error = prediction - targets[sample]
                if not math.isfinite(prediction) or not math.isfinite(error):
                    return INVALID_RESULT
                errors.append(error)
            for feature in range(features):
                gradient = 0.0
                for position, sample in enumerate(batch):
                    gradient += matrix[sample * features + feature] * errors[position]
                update = (learning_rate * gradient) / len(batch)
                weights[feature] -= update
                if not math.isfinite(gradient) or not math.isfinite(update) or not math.isfinite(weights[feature]):
                    return INVALID_RESULT
            error_sum = 0.0
            for error in errors:
                error_sum += error
            mean_error = error_sum / len(batch)
            bias_update = learning_rate * mean_error
            bias -= bias_update
            if not all(math.isfinite(value) for value in (error_sum, mean_error, bias_update, bias)):
                return INVALID_RESULT
    return weights + [bias]
