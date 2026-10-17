"""Independent reference for the bounded Rust projected-gradient SVC adapter."""

from __future__ import annotations

import math

MAX_INPUT_VALUES = 108
MAX_PARSEABLE_INPUT_VALUES = 109
MAX_TRAINING_ROWS = 8
MAX_FEATURES = 4
MAX_TEST_ROWS = 16


def _kernel(left: tuple[float, ...], right: tuple[float, ...], kind: int) -> float:
    if kind == 0:
        total = 0.0
        for index in range(len(left)):
            total += left[index] * right[index]
        return total
    norm_squared = 0.0
    for index in range(len(left)):
        difference = left[index] - right[index]
        norm_squared += difference * difference
    return math.exp(-norm_squared)


def _fit_and_scores(
    labels: tuple[float, ...],
    training: tuple[tuple[float, ...], ...],
    testing: tuple[tuple[float, ...], ...],
    kind: int,
) -> tuple[int, tuple[float, ...]]:
    n = len(labels)
    kernel_matrix = [
        [_kernel(training[i], training[j], kind) for j in range(n)]
        for i in range(n)
    ]
    optimum = [0.5] * n
    for iteration in range(5000):
        gradient = [0.0] * n
        for i in range(n):
            total = 0.0
            for j in range(n):
                total += optimum[j] * labels[j] * kernel_matrix[i][j]
            gradient[i] = labels[i] * total - 1.0

        old_optimum = optimum.copy()
        learning_rate = 0.1 / (1.0 + iteration / 1000.0)
        for i in range(n):
            optimum[i] = min(1.0, max(0.0, optimum[i] - learning_rate * gradient[i]))

        sum_label_lambda = 0.0
        for i in range(n):
            sum_label_lambda += optimum[i] * labels[i]
        correction = sum_label_lambda / n
        for _ in range(10):
            for i in range(n):
                delta = correction * labels[i]
                optimum[i] = min(1.0, max(0.0, optimum[i] - delta))
            sum_label_lambda = 0.0
            for i in range(n):
                sum_label_lambda += optimum[i] * labels[i]
            correction = sum_label_lambda / n
            if abs(sum_label_lambda) < 1e-10:
                break

        difference_squared = 0.0
        for i in range(n):
            difference = optimum[i] - old_optimum[i]
            difference_squared += difference * difference
        if math.sqrt(difference_squared) < 1e-8:
            break

    offset_total = 0.0
    offset_count = 0
    for i in range(n):
        if optimum[i] > 1e-5 and optimum[i] < 1.0 - 1e-5:
            kernel_sum = 0.0
            for j in range(n):
                kernel_sum += optimum[j] * labels[j] * _kernel(training[j], training[i], kind)
            offset_total += labels[i] - kernel_sum
            offset_count += 1
    if offset_count == 0:
        for i in range(n):
            kernel_sum = 0.0
            for j in range(n):
                kernel_sum += optimum[j] * labels[j] * _kernel(training[j], training[i], kind)
            offset_total += labels[i] - kernel_sum
        offset = offset_total / n
    else:
        offset = offset_total / offset_count

    scores: list[float] = []
    mask = 0
    for index, observation in enumerate(testing):
        total = 0.0
        for j in range(n):
            total += optimum[j] * labels[j] * _kernel(training[j], observation, kind)
        score = total + offset
        scores.append(score)
        if score >= 0.0:
            mask |= 1 << index
    return mask, tuple(scores)


def _parse(
    values: list[int] | tuple[int, ...],
) -> tuple[int, tuple[float, ...], tuple[tuple[float, ...], ...], tuple[tuple[float, ...], ...], int] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_PARSEABLE_INPUT_VALUES
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return None
    n, dimension, kind, query_count = values[:4]
    if not 2 <= n <= MAX_TRAINING_ROWS or not 1 <= dimension <= MAX_FEATURES:
        return None
    if kind not in (0, 1) or not 1 <= query_count <= MAX_TEST_ROWS:
        return None
    expected_length = 4 + n + n * dimension + query_count * dimension
    if len(values) != expected_length:
        return None
    label_values = values[4:4 + n]
    if any(label not in (-1, 1) for label in label_values) or -1 not in label_values or 1 not in label_values:
        return None
    feature_values = values[4 + n:]
    if any(value < -4 or value > 4 for value in feature_values):
        return None
    training_start = 4 + n
    training = tuple(
        tuple(float(values[training_start + row * dimension + column]) for column in range(dimension))
        for row in range(n)
    )
    testing_start = training_start + n * dimension
    testing = tuple(
        tuple(float(values[testing_start + row * dimension + column]) for column in range(dimension))
        for row in range(query_count)
    )
    labels = tuple(float(label) for label in label_values)
    return kind, labels, training, testing, query_count


def expected_output(values: list[int] | tuple[int, ...] | None) -> int:
    """Return the prediction bitmask, or -1 for an invalid frame/domain."""
    if values is None:
        return -1
    parsed = _parse(values)
    if parsed is None:
        return -1
    kind, labels, training, testing, _ = parsed
    mask, _ = _fit_and_scores(labels, training, testing, kind)
    return mask


def decision_scores(values: list[int] | tuple[int, ...]) -> tuple[float, ...] | None:
    """Expose scores for fixture authoring so cases can avoid near-zero margins."""
    parsed = _parse(values)
    if parsed is None:
        return None
    kind, labels, training, testing, _ = parsed
    _, scores = _fit_and_scores(labels, training, testing, kind)
    return scores
