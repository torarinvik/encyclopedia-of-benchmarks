"""Oracle for the pinned Python seeded ±1 perceptron."""

from __future__ import annotations

import math
from collections.abc import Sequence


MAX_SAMPLES = 8
MAX_FEATURES = 4
MAX_QUERIES = 4
MAX_INPUT_LENGTH = 61
MAX_PARSEABLE_INPUT_LENGTH = 62
MAX_OUTPUT_LENGTH = 12
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_INITIAL_RANDOM_WEIGHTS = (
    0.8444218515250481,
    0.7579544029403025,
    0.420571580830845,
    0.25891675029296335,
)


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


def _sign(value: float) -> int:
    return 1 if value >= 0.0 else -1


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
    targets = [_int(data[labels_start + row], -1, 1) for row in range(samples)]
    query_start = query_count_index + 1
    queries = [
        data[query_start + row * features : query_start + (row + 1) * features]
        for row in range(query_count)
    ]
    if any(target not in (-1, 1) for target in targets):
        return INVALID_RESULT, []
    if any(_int(value, -2, 2) is None for row in matrix + queries for value in row):
        return INVALID_RESULT, []

    bias_feature = -1.0
    initial_weights = [bias_feature, *_INITIAL_RANDOM_WEIGHTS[:features]]
    training_rows = [[bias_feature, *row] for row in matrix]
    weights = list(initial_weights)
    epoch_count = 0
    for _ in range(epochs):
        has_misclassified = False
        for row, target_value in zip(training_rows, targets):
            weighted_sum = 0.0
            for weight, feature in zip(weights, row):
                weighted_sum += weight * feature
            prediction = _sign(weighted_sum)
            target = int(target_value)
            if prediction != target:
                error = target - prediction
                for index, feature in enumerate(row):
                    weights[index] += learning_rate * error * feature
                has_misclassified = True
        epoch_count += 1
        if not has_misclassified:
            break

    predictions: list[float] = []
    for query in queries:
        weighted_sum = 0.0
        for weight, feature in zip(weights, [bias_feature, *query]):
            weighted_sum += weight * feature
        predictions.append(float(_sign(weighted_sum)))
    output = [float(epoch_count), float(features + 1), *weights, float(query_count), *predictions]
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output

