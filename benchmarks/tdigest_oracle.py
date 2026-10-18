"""Source-faithful bounded oracle for TheAlgorithms Java TDigest."""

from __future__ import annotations

import math
from collections.abc import Sequence


MIN_COMPRESSION = 10
MAX_COMPRESSION = 20
MAX_SAMPLES = 32
MAX_QUERIES = 4
MAX_INPUT_LENGTH = 2 + MAX_SAMPLES + 1 + MAX_QUERIES + 1 + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = 2 + 2 * MAX_QUERIES
BUFFER_FACTOR = 5
CENTROID_SLOTS_PER_UNIT = 2
INSERTION_SORT_THRESHOLD = 16
TWO_PI = 2.0 * math.pi
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_float(value: object) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    try:
        result = float(value)
    except OverflowError:
        return None
    return result if math.isfinite(result) else None


def _integer(value: float, low: int, high: int) -> int | None:
    if value < low or value > high or value != math.trunc(value):
        return None
    return int(value)


def _interpolate(x0: float, y0: float, x1: float, y1: float, x: float) -> float:
    if x1 <= x0:
        return y1
    return y0 + (x - x0) / (x1 - x0) * (y1 - y0)


def _quantile_limit(compression: float, q: float) -> float:
    bounded = min(1.0, max(0.0, q))
    k = compression / TWO_PI * math.asin(2.0 * bounded - 1.0) + 1.0
    angle = k * TWO_PI / compression
    if angle >= math.pi / 2.0:
        return 1.0
    if angle <= -math.pi / 2.0:
        return 0.0
    return (math.sin(angle) + 1.0) / 2.0


def _flush_buffer(compression: float, samples: Sequence[float]) -> tuple[list[float], list[float]]:
    """Fold one unit-weight insertion buffer into sorted centroids."""
    values = sorted(samples)
    weights = [1.0] * len(values)
    total_weight = 0.0
    for weight in weights:
        total_weight += weight

    centroid_capacity = CENTROID_SLOTS_PER_UNIT * (math.ceil(compression) + 2)
    means = [values[0]]
    centroid_weights = [weights[0]]
    weight_of_closed_centroids = 0.0
    weight_limit = total_weight * _quantile_limit(compression, 0.0)
    last = 0

    for i in range(1, len(values)):
        projected = centroid_weights[last] + weights[i]
        room_left = weight_of_closed_centroids + projected <= weight_limit
        if room_left or last == centroid_capacity - 1:
            centroid_weights[last] = projected
            means[last] += (values[i] - means[last]) * weights[i] / projected
        else:
            weight_of_closed_centroids += centroid_weights[last]
            weight_limit = total_weight * _quantile_limit(
                compression, weight_of_closed_centroids / total_weight
            )
            last += 1
            means.append(values[i])
            centroid_weights.append(weights[i])
    return means, centroid_weights


def _quantile(
    q: float,
    means: Sequence[float],
    weights: Sequence[float],
    total_weight: float,
    minimum: float,
    maximum: float,
) -> float:
    if len(means) == 1:
        return means[0]
    index = q * total_weight
    if index <= 0.0:
        return minimum
    if index >= total_weight:
        return maximum

    previous_value = minimum
    previous_index = 0.0
    current_index = 0.0
    for i, mean in enumerate(means):
        current_index += weights[i] / 2.0 if i == 0 else (weights[i - 1] + weights[i]) / 2.0
        if index < current_index:
            return _interpolate(previous_index, previous_value, current_index, mean, index)
        previous_value = mean
        previous_index = current_index
    return _interpolate(previous_index, previous_value, total_weight, maximum, index)


def _cdf(
    value: float,
    means: Sequence[float],
    weights: Sequence[float],
    total_weight: float,
    minimum: float,
    maximum: float,
) -> float:
    if value < minimum:
        return 0.0
    if value > maximum:
        return 1.0
    if maximum <= minimum:
        return 0.5

    previous_value = minimum
    previous_index = 0.0
    current_index = 0.0
    for i, mean in enumerate(means):
        current_index += weights[i] / 2.0 if i == 0 else (weights[i - 1] + weights[i]) / 2.0
        if value < mean:
            return _interpolate(previous_value, previous_index, mean, current_index, value) / total_weight
        previous_value = mean
        previous_index = current_index
    return _interpolate(previous_value, previous_index, maximum, total_weight, value) / total_weight


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
    if input_length != len(values) or input_length < 7:
        return INVALID_RESULT, []

    parsed = [_finite_float(value) for value in values]
    if any(value is None for value in parsed):
        return INVALID_RESULT, []
    data = [float(value) for value in parsed]
    compression = _integer(data[0], MIN_COMPRESSION, MAX_COMPRESSION)
    sample_count = _integer(data[1], 1, MAX_SAMPLES)
    if compression is None or sample_count is None:
        return INVALID_RESULT, []
    quantile_count_index = 2 + sample_count
    if input_length <= quantile_count_index:
        return INVALID_RESULT, []
    quantile_count = _integer(data[quantile_count_index], 1, MAX_QUERIES)
    if quantile_count is None:
        return INVALID_RESULT, []
    quantile_start = quantile_count_index + 1
    cdf_count_index = quantile_start + quantile_count
    if input_length <= cdf_count_index:
        return INVALID_RESULT, []
    cdf_count = _integer(data[cdf_count_index], 1, MAX_QUERIES)
    if cdf_count is None:
        return INVALID_RESULT, []
    cdf_start = cdf_count_index + 1
    if input_length != cdf_start + cdf_count or input_length > MAX_INPUT_LENGTH:
        return INVALID_RESULT, []

    samples = data[2:quantile_count_index]
    probabilities = data[quantile_start:cdf_count_index]
    cdf_values = data[cdf_start:]
    if any(
        value < -8.0 or value > 8.0 or value != math.trunc(value)
        for value in samples + cdf_values
    ):
        return INVALID_RESULT, []
    if any(
        value < 0.0 or value > 1.0 or value * 4.0 != math.trunc(value * 4.0)
        for value in probabilities
    ):
        return INVALID_RESULT, []

    means, weights = _flush_buffer(float(compression), samples)
    total_weight = float(sample_count)
    minimum = min(samples)
    maximum = max(samples)
    output = [float(quantile_count)]
    output.extend(
        _quantile(q, means, weights, total_weight, minimum, maximum)
        for q in probabilities
    )
    output.append(float(cdf_count))
    output.extend(
        _cdf(x, means, weights, total_weight, minimum, maximum) for x in cdf_values
    )
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output


def expected_result(values: Sequence[object] | None) -> tuple[int, list[float]]:
    return expected_output(values)
