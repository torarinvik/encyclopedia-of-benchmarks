"""Oracle for the pinned R binary and direct-multiclass perceptron."""

from __future__ import annotations

import math
from collections.abc import Sequence


MAX_SAMPLES = 8
MAX_FEATURES = 4
MAX_QUERIES = 4
MAX_INPUT_LENGTH = 61
MAX_PARSEABLE_INPUT_LENGTH = 62
MAX_OUTPUT_LENGTH = 25
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _float(value: object) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    try:
        result = float(value)
    except OverflowError:
        return None
    return result if math.isfinite(result) else None


def _int(value: float, low: int, high: int) -> int | None:
    if value < low or value > high or value != math.trunc(value):
        return None
    return int(value)


def expected_output(
    values: Sequence[object],
    *,
    input_length: int | None = None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, list[float]]:
    if input_length is None:
        input_length = len(values)
    if input_is_null or input_length < 0 or input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, []
    if input_length != len(values) or input_length < 8:
        return INVALID_RESULT, []
    parsed = [_float(value) for value in values]
    if any(value is None for value in parsed):
        return INVALID_RESULT, []
    data = [float(value) for value in parsed]

    learning_rate = data[0]
    epochs = _int(data[1], 1, 12)
    samples = _int(data[2], 2, MAX_SAMPLES)
    features = _int(data[3], 1, MAX_FEATURES)
    if (
        learning_rate not in (0.25, 0.5, 0.75, 1.0)
        or epochs is None
        or samples is None
        or features is None
    ):
        return INVALID_RESULT, []

    feature_start = 4
    labels_start = feature_start + samples * features
    query_count_index = labels_start + samples
    if input_length <= query_count_index:
        return INVALID_RESULT, []
    query_count = _int(data[query_count_index], 1, MAX_QUERIES)
    if query_count is None or input_length != query_count_index + 1 + query_count * features:
        return INVALID_RESULT, []
    if input_length > MAX_INPUT_LENGTH:
        return INVALID_RESULT, []

    matrix = [
        data[feature_start + row * features : feature_start + (row + 1) * features]
        for row in range(samples)
    ]
    labels = [_int(data[labels_start + row], -2, 2) for row in range(samples)]
    if any(label is None for label in labels):
        return INVALID_RESULT, []
    classes = sorted(set(int(label) for label in labels))
    if len(classes) not in (2, 3):
        return INVALID_RESULT, []
    query_start = query_count_index + 1
    queries = [
        data[query_start + row * features : query_start + (row + 1) * features]
        for row in range(query_count)
    ]
    if any(_int(value, -2, 2) is None for row in matrix + queries for value in row):
        return INVALID_RESULT, []

    augmented = [[1.0, *row] for row in matrix]
    augmented_queries = [[1.0, *row] for row in queries]
    if len(classes) == 2:
        weights = [0.0] * (features + 1)
        encoded = [-1 if int(label) == classes[0] else 1 for label in labels]
        for _ in range(epochs):
            for row, label in zip(augmented, encoded):
                score = sum(weight * feature for weight, feature in zip(weights, row))
                if label * score <= 0.0:
                    weights = [
                        weight + learning_rate * label * feature
                        for weight, feature in zip(weights, row)
                    ]
        predictions = [
            float(classes[1] if sum(w * x for w, x in zip(weights, row)) >= 0.0 else classes[0])
            for row in augmented_queries
        ]
        parameters = weights
    else:
        class_index = {label: index for index, label in enumerate(classes)}
        weights_matrix = [[0.0] * (features + 1) for _ in classes]
        for _ in range(epochs):
            for row, label_value in zip(augmented, labels):
                scores = [sum(w * x for w, x in zip(weight_row, row)) for weight_row in weights_matrix]
                predicted = max(range(len(scores)), key=scores.__getitem__)
                target = class_index[int(label_value)]
                if predicted != target:
                    weights_matrix[target] = [
                        weight + learning_rate * feature
                        for weight, feature in zip(weights_matrix[target], row)
                    ]
                    weights_matrix[predicted] = [
                        weight - learning_rate * feature
                        for weight, feature in zip(weights_matrix[predicted], row)
                    ]
        predictions = []
        for row in augmented_queries:
            scores = [
                sum(weight * feature for weight, feature in zip(weight_row, row))
                for weight_row in weights_matrix
            ]
            predicted = max(range(len(scores)), key=scores.__getitem__)
            predictions.append(float(classes[predicted]))
        parameters = [weight for weight_row in weights_matrix for weight in weight_row]

    output = [float(len(classes)), *(float(label) for label in classes), float(len(parameters)), *parameters, float(query_count), *predictions]
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output

