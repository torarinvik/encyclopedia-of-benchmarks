"""Oracle for the bounded binary-classification path of the pinned R k-NN."""

from __future__ import annotations

from collections.abc import Sequence

MIN_TRAINING_COUNT = 1
MAX_TRAINING_COUNT = 32
MIN_FEATURE_COUNT = 1
MAX_FEATURE_COUNT = 8
MIN_FEATURE_VALUE = -32
MAX_FEATURE_VALUE = 32
MAX_VALID_INPUT_VALUES = 3 + MAX_TRAINING_COUNT * (MAX_FEATURE_COUNT + 1) + MAX_FEATURE_COUNT
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode_input(values: Sequence[int] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    training_count, feature_count, neighbor_count = values[:3]
    if not MIN_TRAINING_COUNT <= training_count <= MAX_TRAINING_COUNT:
        return None
    if not MIN_FEATURE_COUNT <= feature_count <= MAX_FEATURE_COUNT:
        return None
    if not 1 <= neighbor_count <= training_count or neighbor_count % 2 == 0:
        return None

    expected_length = 3 + training_count * feature_count + training_count + feature_count
    if len(values) != expected_length:
        return None
    feature_end = 3 + training_count * feature_count
    label_end = feature_end + training_count
    flat_features = values[3:feature_end]
    labels = values[feature_end:label_end]
    query = values[label_end:]
    if any(not MIN_FEATURE_VALUE <= value <= MAX_FEATURE_VALUE for value in (*flat_features, *query)):
        return None
    if any(label not in (0, 1) for label in labels):
        return None

    features = [
        tuple(flat_features[row * feature_count : (row + 1) * feature_count])
        for row in range(training_count)
    ]
    distances = [
        sum((coordinate - query[index]) ** 2 for index, coordinate in enumerate(row))
        for row in features
    ]
    if len(set(distances)) != training_count:
        return None
    return neighbor_count, labels, distances


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the predicted binary class ID, or the invalid-input sentinel."""
    if input_is_null:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (list, tuple))
        or input_length != len(values)
    ):
        return INVALID_RESULT
    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT
    neighbor_count, labels, distances = decoded
    nearest_indices = sorted(range(len(distances)), key=distances.__getitem__)[:neighbor_count]
    class_zero_votes = sum(labels[index] == 0 for index in nearest_indices)
    class_one_votes = neighbor_count - class_zero_votes
    return 0 if class_zero_votes > class_one_votes else 1
