"""Oracle for the bounded pinned vectorized linear-regression gradient descent."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_SAMPLE_COUNT = 2
MAX_SAMPLE_COUNT = 8
MIN_FEATURE_COUNT = 2
MAX_FEATURE_COUNT = 4
MIN_ITERATIONS = 10
MAX_ITERATIONS = 128
MIN_ALPHA = 0.0001
MAX_ALPHA = 0.01
MIN_FEATURE_OR_LABEL = -1.0
MAX_FEATURE_OR_LABEL = 1.0
MAX_INPUT_LENGTH = 4 + MAX_SAMPLE_COUNT * MAX_FEATURE_COUNT + MAX_SAMPLE_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_FEATURE_COUNT
ABSOLUTE_TOLERANCE = 1e-10
RELATIVE_TOLERANCE = 1e-10


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return learned theta or ``None`` for an invalid bounded input."""
    if not isinstance(values, (list, tuple)):
        return None
    if not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) not in (int, float) for value in values):
        return None
    try:
        numeric_values = [float(value) for value in values]
    except (OverflowError, ValueError, TypeError):
        return None
    if any(not math.isfinite(value) for value in numeric_values):
        return None

    sample_value, feature_value, iteration_value, alpha = numeric_values[:4]
    if not sample_value.is_integer() or not feature_value.is_integer() or not iteration_value.is_integer():
        return None
    sample_count = int(sample_value)
    feature_count = int(feature_value)
    iterations = int(iteration_value)
    if not MIN_SAMPLE_COUNT <= sample_count <= MAX_SAMPLE_COUNT:
        return None
    if not MIN_FEATURE_COUNT <= feature_count <= MAX_FEATURE_COUNT:
        return None
    if not MIN_ITERATIONS <= iterations <= MAX_ITERATIONS:
        return None
    if not MIN_ALPHA <= alpha <= MAX_ALPHA:
        return None
    if len(numeric_values) != 4 + sample_count * feature_count + sample_count:
        return None

    feature_end = 4 + sample_count * feature_count
    flat_features = numeric_values[4:feature_end]
    labels = numeric_values[feature_end:]
    features = [
        flat_features[row * feature_count : (row + 1) * feature_count]
        for row in range(sample_count)
    ]
    if any(row[0] != 1.0 for row in features):
        return None
    if any(
        not MIN_FEATURE_OR_LABEL <= value <= MAX_FEATURE_OR_LABEL
        for row in features
        for value in row[1:]
    ):
        return None
    if any(
        not MIN_FEATURE_OR_LABEL <= label <= MAX_FEATURE_OR_LABEL
        for label in labels
    ):
        return None

    theta = [0.0] * feature_count
    for _ in range(iterations):
        predictions = [
            sum(features[row][column] * theta[column] for column in range(feature_count))
            for row in range(sample_count)
        ]
        errors = [predictions[row] - labels[row] for row in range(sample_count)]
        gradients = [
            sum(features[row][column] * errors[row] for row in range(sample_count))
            / sample_count
            for column in range(feature_count)
        ]
        for column in range(feature_count):
            theta[column] -= alpha * gradients[column]
    return theta
