"""Oracle for the bounded Java multinomial Naive Bayes classifier contract."""

from __future__ import annotations

from collections.abc import Sequence
import math
import struct

MAX_FITS = 2
MAX_TRAIN_ROWS = 16
MAX_FEATURE_WIDTH = 8
MAX_PREDICTIONS = 8
MAX_CLASS_LABEL = 7
MAX_FEATURE_COUNT = 100
SCORE_MARGIN_MIN = 1e-8
MAX_VALID_INPUT_LENGTH = 1 + MAX_FITS * (2 + MAX_TRAIN_ROWS + MAX_TRAIN_ROWS * MAX_FEATURE_WIDTH) + 2 + MAX_PREDICTIONS * MAX_FEATURE_WIDTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 1 + MAX_PREDICTIONS
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SEMANTIC_CASE_IDS = frozenset({
    "single_class_zero_count_vectors",
    "class_discriminative_batch",
    "class_prior_dominates_empty_count_sample",
    "laplace_smoothing_for_zero_features",
    "fit_reset_replaces_previous_model",
    "batch_prediction_preserves_order",
    "maximum_training_shape",
    "maximum_prediction_batch",
    "maximum_packed_input_length",
})
ABI_CASE_IDS = frozenset({
    "null_input_positive_length",
    "empty_input",
    "fit_count_zero",
    "fit_count_above_bound",
    "truncated_fit_header",
    "zero_training_rows",
    "training_rows_above_bound",
    "zero_feature_width",
    "feature_width_above_bound",
    "label_below_bound",
    "label_above_bound",
    "negative_training_count",
    "training_count_above_bound",
    "missing_prediction_header",
    "prediction_count_zero",
    "prediction_count_above_bound",
    "prediction_width_mismatch",
    "negative_prediction_count",
    "prediction_count_above_domain",
    "prediction_width_above_bound",
    "ambiguous_score_tie",
    "truncated_prediction_matrix",
    "trailing_input_word",
    "null_output",
    "short_output_capacity",
    "exact_output_capacity",
    "maximum_output_one_byte_short",
    "invalid_input_precedes_output_error",
})


def _parse_and_predict(values: Sequence[int] | None) -> list[int] | None:
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None

    cursor = 0
    fit_count = values[cursor]
    cursor += 1
    if not 1 <= fit_count <= MAX_FITS:
        return None

    model: dict[int, tuple[int, list[float], float]] | None = None
    feature_width = 0
    for _ in range(fit_count):
        if cursor + 2 > len(values):
            return None
        train_rows, current_width = values[cursor:cursor + 2]
        cursor += 2
        if not 1 <= train_rows <= MAX_TRAIN_ROWS:
            return None
        if not 1 <= current_width <= MAX_FEATURE_WIDTH:
            return None
        required = train_rows + train_rows * current_width
        if cursor + required > len(values):
            return None
        labels = values[cursor:cursor + train_rows]
        cursor += train_rows
        if any(not 0 <= label <= MAX_CLASS_LABEL for label in labels):
            return None
        flat_features = values[cursor:cursor + train_rows * current_width]
        cursor += train_rows * current_width
        if any(not 0 <= count <= MAX_FEATURE_COUNT for count in flat_features):
            return None

        class_stats: dict[int, tuple[int, list[float], float]] = {}
        for row in range(train_rows):
            label = labels[row]
            if label not in class_stats:
                class_stats[label] = (0, [0.0] * current_width, 0.0)
            class_count, sums, total = class_stats[label]
            class_count += 1
            for column in range(current_width):
                count = flat_features[row * current_width + column]
                sums[column] += float(count)
                total += float(count)
            class_stats[label] = (class_count, sums, total)

        model = class_stats
        feature_width = current_width

    if cursor + 2 > len(values):
        return None
    prediction_count, prediction_width = values[cursor:cursor + 2]
    cursor += 2
    if not 1 <= prediction_count <= MAX_PREDICTIONS:
        return None
    if not 1 <= prediction_width <= MAX_FEATURE_WIDTH:
        return None
    if prediction_width != feature_width:
        return None
    required = prediction_count * prediction_width
    if cursor + required != len(values):
        return None
    flat_predictions = values[cursor:]
    if any(not 0 <= count <= MAX_FEATURE_COUNT for count in flat_predictions):
        return None
    if model is None:
        return None

    predictions: list[int] = []
    for row in range(prediction_count):
        sample_start = row * prediction_width
        sample = flat_predictions[sample_start:sample_start + prediction_width]
        scores: list[tuple[float, int]] = []
        for label, (class_count, sums, total) in model.items():
            score = math.log(class_count / sum(stats[0] for stats in model.values()))
            denominator = total + current_width * 1.0
            for column in range(current_width):
                log_likelihood = math.log((sums[column] + 1.0) / denominator)
                score += float(sample[column]) * log_likelihood
            scores.append((score, label))
        scores.sort(reverse=True)
        if len(scores) > 1 and scores[0][0] - scores[1][0] < SCORE_MARGIN_MIN:
            return None
        predictions.append(scores[0][1])
    return predictions


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return predicted labels or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    predictions = _parse_and_predict(values)
    if predictions is None:
        return INVALID_RESULT, b""
    fields = [len(predictions), *predictions]
    output = b"".join(struct.pack("<q", field) for field in fields)
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
