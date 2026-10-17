"""Oracle for one bounded 1-D Kohonen SOM weight update."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_NODES = 1
MAX_NODES = 8
MIN_FEATURES = 1
MAX_FEATURES = 4
MAX_RADIUS = 8
MIN_ALPHA_CODE = 1
MAX_ALPHA_CODE = 16
ALPHA_DENOMINATOR = 16
MIN_VALUE = -8
MAX_VALUE = 8
MAX_VALID_INPUT_LENGTH = 4 + MAX_FEATURES + MAX_NODES * MAX_FEATURES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_NODES * MAX_FEATURES
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _exact_integer(value: int | float) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


def _decode_input(values: Sequence[float] | None):
    if (not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None

    node_count = _exact_integer(values[0])
    feature_count = _exact_integer(values[1])
    radius = _exact_integer(values[2])
    alpha_code = _exact_integer(values[3])
    if node_count is None or not MIN_NODES <= node_count <= MAX_NODES:
        return None
    if feature_count is None or not MIN_FEATURES <= feature_count <= MAX_FEATURES:
        return None
    if radius is None or not 0 <= radius <= MAX_RADIUS:
        return None
    if alpha_code is None or not MIN_ALPHA_CODE <= alpha_code <= MAX_ALPHA_CODE:
        return None
    if len(values) != 4 + feature_count + node_count * feature_count:
        return None

    decoded_values = [_exact_integer(value) for value in values[4:]]
    if any(value is None or not MIN_VALUE <= value <= MAX_VALUE for value in decoded_values):
        return None
    sample = [float(value) for value in decoded_values[:feature_count]]
    weight_values = decoded_values[feature_count:]
    weights = [
        [float(weight_values[node * feature_count + feature])
         for feature in range(feature_count)]
        for node in range(node_count)
    ]
    alpha = alpha_code / ALPHA_DENOMINATOR
    return node_count, feature_count, radius, alpha, sample, weights


def _update_weights(
    radius: int,
    alpha: float,
    sample: list[float],
    weights: list[list[float]],
) -> list[float]:
    """Preserve squared-distance order, first minimum, clipping, and update order."""
    node_count = len(weights)
    feature_count = len(sample)
    distances = [0.0] * node_count
    for node in range(node_count):
        for feature in range(feature_count):
            difference = weights[node][feature] - sample[feature]
            distances[node] += difference * difference

    bmu = 0
    minimum = distances[0]
    for node in range(1, node_count):
        if distances[node] < minimum:
            minimum = distances[node]
            bmu = node

    from_node = max(0, bmu - radius)
    to_node = min(node_count, bmu + radius + 1)
    for node in range(from_node, to_node):
        for feature in range(feature_count):
            weights[node][feature] += alpha * (sample[feature] - weights[node][feature])
    return [weight for row in weights for weight in row]


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return updated row-major weights or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int
                                        or output_capacity < 0):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    node_count, _, radius, alpha, sample, weights = decoded
    output = _update_weights(radius, alpha, sample, weights)
    if (not output or any(not math.isfinite(value) for value in output)):
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
