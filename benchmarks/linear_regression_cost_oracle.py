"""Independent oracle for the bounded multivariate half-MSE calculation."""

from __future__ import annotations

INVALID_RESULT = -1.0e300
MAX_OBSERVATIONS = 64
MAX_FEATURES = 16
MAX_COMPONENT = 1_000
MAX_INPUT_LENGTH = 2 + MAX_OBSERVATIONS * MAX_FEATURES + MAX_FEATURES + MAX_OBSERVATIONS
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def expected_result(values: tuple[int, ...] | list[int]) -> float:
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    observation_count, feature_count = values[:2]
    if (not 1 <= observation_count <= MAX_OBSERVATIONS
            or not 1 <= feature_count <= MAX_FEATURES):
        return INVALID_RESULT
    matrix_length = observation_count * feature_count
    expected_length = 2 + matrix_length + feature_count + observation_count
    if len(values) != expected_length:
        return INVALID_RESULT
    data = values[2:]
    if any(not -MAX_COMPONENT <= value <= MAX_COMPONENT for value in data):
        return INVALID_RESULT

    matrix_end = 2 + matrix_length
    weights = values[matrix_end:matrix_end + feature_count]
    targets = values[matrix_end + feature_count:]
    squared_error_sum = 0.0
    for row in range(observation_count):
        prediction = 0.0
        row_start = 2 + row * feature_count
        for column in range(feature_count):
            prediction += float(values[row_start + column]) * float(weights[column])
        error = prediction - float(targets[row])
        squared_error_sum += error * error
    return squared_error_sum / (2.0 * observation_count)
