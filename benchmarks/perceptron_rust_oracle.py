"""Oracle for the pinned Rust zero-initialized ±1 perceptron."""

from __future__ import annotations

import math
from collections.abc import Sequence


MAX_SAMPLES = 8
MAX_FEATURES = 4
MAX_QUERIES = 4
MAX_INPUT_LENGTH = 61
MAX_PARSEABLE_INPUT_LENGTH = 62
MAX_OUTPUT_LENGTH = 11
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

    max_iterations = _int(data[0], 0, 12)
    learning_rate = data[1]
    samples = _int(data[2], 2, MAX_SAMPLES)
    features = _int(data[3], 1, MAX_FEATURES)
    if (
        max_iterations is None
        or learning_rate not in (0.25, 0.5, 0.75, 1.0)
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
    labels = [_int(data[labels_start + row], -1, 1) for row in range(samples)]
    query_start = query_count_index + 1
    queries = [
        data[query_start + row * features : query_start + (row + 1) * features]
        for row in range(query_count)
    ]
    if any(label not in (-1, 1) for label in labels):
        return INVALID_RESULT, []
    if any(_int(value, -2, 2) is None for row in matrix + queries for value in row):
        return INVALID_RESULT, []

    weights = [0.0] * features
    bias = 0.0
    for _ in range(max_iterations):
        misclassified = 0
        for row, label_value in zip(matrix, labels):
            label = float(label_value)
            score = sum(weight * feature for weight, feature in zip(weights, row)) + bias
            prediction = 1.0 if score >= 0.0 else -1.0
            if prediction != label:
                misclassified += 1
                for index, feature in enumerate(row):
                    weights[index] += learning_rate * label * feature
                bias += learning_rate * label
        if misclassified == 0:
            break

    predictions = []
    for row in queries:
        score = sum(weight * feature for weight, feature in zip(weights, row)) + bias
        predictions.append(1.0 if score >= 0.0 else -1.0)
    output = [float(features), *weights, bias, float(query_count), *predictions]
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output

