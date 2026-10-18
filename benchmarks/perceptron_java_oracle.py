"""Oracle for the pinned Java 0/1 online perceptron."""

from __future__ import annotations

import math
from collections.abc import Sequence


MAX_SAMPLES = 8
MAX_FEATURES = 4
MAX_QUERIES = 4
MAX_INPUT_LENGTH = 61
MAX_PARSEABLE_INPUT_LENGTH = 62
MAX_OUTPUT_LENGTH = 13
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
    if input_length != len(values) or input_length < 9:
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
    labels = [_int(data[labels_start + row], 0, 1) for row in range(samples)]
    query_start = query_count_index + 1
    queries = [
        data[query_start + row * features : query_start + (row + 1) * features]
        for row in range(query_count)
    ]
    if any(label is None for label in labels):
        return INVALID_RESULT, []
    if any(_int(value, -2, 2) is None for row in matrix + queries for value in row):
        return INVALID_RESULT, []

    weights = [0.0] * features
    bias = 0.0
    epochs_run = 0
    converged = False
    for epoch in range(epochs):
        updated = False
        for row, label_value in zip(matrix, labels):
            label = int(label_value)
            weighted_sum = bias
            for weight, feature in zip(weights, row):
                weighted_sum += weight * feature
            prediction = 1 if weighted_sum >= 0.0 else 0
            error = label - prediction
            if error != 0:
                for index, feature in enumerate(row):
                    weights[index] += learning_rate * error * feature
                bias += learning_rate * error
                updated = True
        epochs_run = epoch + 1
        if not updated:
            converged = True
            break

    predictions: list[float] = []
    for row in queries:
        weighted_sum = bias
        for weight, feature in zip(weights, row):
            weighted_sum += weight * feature
        predictions.append(1.0 if weighted_sum >= 0.0 else 0.0)
    output = [float(features), *weights, bias, float(epochs_run), float(converged), float(query_count), *predictions]
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output

