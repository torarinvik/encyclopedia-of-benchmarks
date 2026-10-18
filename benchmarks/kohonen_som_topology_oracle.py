"""Oracle for one bounded 2-D Kohonen SOM topology update."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_MAP_SIZE = 1
MAX_MAP_SIZE = 4
MIN_FEATURES = 1
MAX_FEATURES = 3
MAX_RADIUS = 8
MIN_ALPHA_CODE = 1
MAX_ALPHA_CODE = 16
ALPHA_DENOMINATOR = 16
MIN_VALUE = -8
MAX_VALUE = 8
MAX_VALID_INPUT_LENGTH = 4 + MAX_FEATURES + MAX_MAP_SIZE * MAX_MAP_SIZE * MAX_FEATURES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 1 + MAX_MAP_SIZE * MAX_MAP_SIZE * MAX_FEATURES
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

    map_size = _exact_integer(values[0])
    feature_count = _exact_integer(values[1])
    radius = _exact_integer(values[2])
    alpha_code = _exact_integer(values[3])
    if map_size is None or not MIN_MAP_SIZE <= map_size <= MAX_MAP_SIZE:
        return None
    if feature_count is None or not MIN_FEATURES <= feature_count <= MAX_FEATURES:
        return None
    if radius is None or not 0 <= radius <= MAX_RADIUS:
        return None
    if alpha_code is None or not MIN_ALPHA_CODE <= alpha_code <= MAX_ALPHA_CODE:
        return None
    if len(values) != 4 + feature_count + map_size * map_size * feature_count:
        return None

    decoded_values = [_exact_integer(value) for value in values[4:]]
    if any(value is None or not MIN_VALUE <= value <= MAX_VALUE for value in decoded_values):
        return None
    sample = [float(value) for value in decoded_values[:feature_count]]
    weight_values = decoded_values[feature_count:]
    weights = [
        [
            [
                float(weight_values[(x * map_size + y) * feature_count + feature])
                for feature in range(feature_count)
            ]
            for y in range(map_size)
        ]
        for x in range(map_size)
    ]
    alpha = alpha_code / ALPHA_DENOMINATOR
    return map_size, feature_count, radius, alpha, sample, weights


def _update_weights(
    map_size: int,
    feature_count: int,
    radius: int,
    alpha: float,
    sample: list[float],
    weights: list[list[list[float]]],
) -> list[float]:
    """Preserve source distance order, first minimum, Gaussian and update order."""
    distances = [[0.0] * map_size for _ in range(map_size)]
    for x in range(map_size):
        for y in range(map_size):
            distance_squared = 0.0
            for feature in range(feature_count):
                difference = weights[x][y][feature] - sample[feature]
                distance_squared += difference * difference
            distances[x][y] = math.sqrt(distance_squared)

    bmu_x = 0
    bmu_y = 0
    minimum = distances[0][0]
    for x in range(map_size):
        for y in range(map_size):
            if distances[x][y] < minimum:
                minimum = distances[x][y]
                bmu_x = x
                bmu_y = y

    from_x = max(0, bmu_x - radius)
    to_x = min(map_size, bmu_x + radius + 1)
    from_y = max(0, bmu_y - radius)
    to_y = min(map_size, bmu_y + radius + 1)
    for x in range(from_x, to_x):
        for y in range(from_y, to_y):
            dx = bmu_x - x
            dy = bmu_y - y
            grid_distance_squared = dx * dx + dy * dy
            scale_factor = math.exp(-grid_distance_squared / (2.0 * alpha * alpha))
            for feature in range(feature_count):
                weights[x][y][feature] += (
                    alpha * scale_factor * (sample[feature] - weights[x][y][feature])
                )

    output = [minimum]
    output.extend(
        weights[x][y][feature]
        for x in range(map_size)
        for y in range(map_size)
        for feature in range(feature_count)
    )
    return output


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return d_min followed by updated weights, or the documented ABI error."""
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
    map_size, feature_count, radius, alpha, sample, weights = decoded
    output = _update_weights(map_size, feature_count, radius, alpha, sample, weights)
    if not output or any(not math.isfinite(value) for value in output):
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
