"""Oracle for the pinned Rust ID3/entropy decision tree."""

from __future__ import annotations

import math
from collections.abc import Sequence


MAX_SAMPLES = 8
MAX_FEATURES = 4
MAX_QUERIES = 4
MAX_INPUT_LENGTH = 61
MAX_PARSEABLE_INPUT_LENGTH = 62
MAX_OUTPUT_LENGTH = 5
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_float(value: object) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    try:
        parsed = float(value)
    except OverflowError:
        return None
    return parsed if math.isfinite(parsed) else None


def _integer(value: float, low: int, high: int) -> int | None:
    if value < low or value > high or value != math.trunc(value):
        return None
    return int(value)


def _entropy(labels: Sequence[int]) -> float:
    if not labels:
        return 0.0
    counts: dict[int, int] = {}
    for label in labels:
        counts[label] = counts.get(label, 0) + 1
    total = float(len(labels))
    return -sum((count / total) * math.log2(count / total) for count in counts.values())


def _majority(labels: Sequence[int]) -> int:
    counts: dict[int, int] = {}
    for label in labels:
        counts[label] = counts.get(label, 0) + 1
    return max(counts, key=counts.__getitem__)


def _build_tree(
    rows: list[tuple[list[float], int]],
    feature_count: int,
    max_depth: int,
    min_samples_split: int,
    depth: int,
) -> tuple[str, int] | tuple[str, int, float, object, object]:
    labels = [label for _, label in rows]
    if (
        len(set(labels)) == 1
        or len(rows) < min_samples_split
        or depth >= max_depth
        or feature_count == 0
    ):
        return ("leaf", _majority(labels))

    parent_entropy = _entropy(labels)
    best_gain = 0.0
    best_feature = -1
    best_threshold = 0.0
    for feature in range(feature_count):
        sorted_rows = sorted(rows, key=lambda row: row[0][feature])
        for index in range(1, len(sorted_rows)):
            left_value = sorted_rows[index - 1][0][feature]
            right_value = sorted_rows[index][0][feature]
            if left_value == right_value:
                continue
            threshold = (left_value + right_value) / 2.0
            left_labels = [label for _, label in sorted_rows[:index]]
            right_labels = [label for _, label in sorted_rows[index:]]
            left_weight = index / len(rows)
            right_weight = (len(rows) - index) / len(rows)
            gain = parent_entropy - left_weight * _entropy(left_labels) - right_weight * _entropy(right_labels)
            if gain > best_gain:
                best_gain = gain
                best_feature = feature
                best_threshold = threshold

    if best_feature < 0:
        return ("leaf", _majority(labels))

    left_rows = [row for row in rows if row[0][best_feature] < best_threshold]
    right_rows = [row for row in rows if row[0][best_feature] >= best_threshold]
    if not left_rows or not right_rows:
        return ("leaf", _majority(labels))
    return (
        "node",
        best_feature,
        best_threshold,
        _build_tree(left_rows, feature_count, max_depth, min_samples_split, depth + 1),
        _build_tree(right_rows, feature_count, max_depth, min_samples_split, depth + 1),
    )


def _predict(tree: tuple, features: Sequence[float]) -> int:
    if tree[0] == "leaf":
        return int(tree[1])
    _, feature, threshold, left, right = tree
    return _predict(left if features[int(feature)] < float(threshold) else right, features)


def expected_output(
    values: Sequence[object] | None,
    *,
    input_length: int | None = None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, list[float]]:
    if not isinstance(input_is_null, bool) or not isinstance(output_is_null, bool):
        return INVALID_RESULT, []
    if input_is_null or values is None:
        return INVALID_RESULT, []
    if input_length is None:
        input_length = len(values)
    if (
        isinstance(input_length, bool)
        or not isinstance(input_length, int)
        or input_length < 0
        or input_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID_RESULT, []
    if output_capacity is not None and (
        isinstance(output_capacity, bool)
        or not isinstance(output_capacity, int)
        or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length != len(values) or input_length < 10:
        return INVALID_RESULT, []

    parsed = [_finite_float(value) for value in values]
    if any(value is None for value in parsed):
        return INVALID_RESULT, []
    data = [float(value) for value in parsed]
    max_depth = _integer(data[0], 0, 6)
    min_samples_split = _integer(data[1], 2, MAX_SAMPLES)
    sample_count = _integer(data[2], 2, MAX_SAMPLES)
    feature_count = _integer(data[3], 1, MAX_FEATURES)
    if None in (max_depth, min_samples_split, sample_count, feature_count):
        return INVALID_RESULT, []
    assert max_depth is not None and min_samples_split is not None
    assert sample_count is not None and feature_count is not None

    training_start = 4
    row_width = feature_count + 1
    query_count_index = training_start + sample_count * row_width
    if input_length <= query_count_index:
        return INVALID_RESULT, []
    query_count = _integer(data[query_count_index], 1, MAX_QUERIES)
    if query_count is None:
        return INVALID_RESULT, []
    query_start = query_count_index + 1
    if input_length != query_start + query_count * feature_count or input_length > MAX_INPUT_LENGTH:
        return INVALID_RESULT, []

    rows: list[tuple[list[float], int]] = []
    for row_index in range(sample_count):
        offset = training_start + row_index * row_width
        features = data[offset : offset + feature_count]
        label = _integer(data[offset + feature_count], 0, 2)
        if label is None or any(
            value < -4.0 or value > 4.0 or value * 4.0 != math.trunc(value * 4.0)
            for value in features
        ):
            return INVALID_RESULT, []
        rows.append((features, label))

    queries: list[list[float]] = []
    for row_index in range(query_count):
        offset = query_start + row_index * feature_count
        query = data[offset : offset + feature_count]
        if any(
            value < -4.0 or value > 4.0 or value * 4.0 != math.trunc(value * 4.0)
            for value in query
        ):
            return INVALID_RESULT, []
        queries.append(query)

    tree = _build_tree(rows, feature_count, max_depth, min_samples_split, 0)
    output = [float(query_count), *[float(_predict(tree, query)) for query in queries]]
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
