"""Oracle for a bounded one-feature squared-error gradient boosting regressor."""
from __future__ import annotations
import math

INVALID_RESULT = -1e300
MAX_SAMPLES = 16
MAX_ESTIMATORS = 12
MAX_INPUT_LENGTH = 4 + 2 * MAX_SAMPLES


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return INVALID_RESULT
    n, estimators, learning_micro, query = values[:4]
    if not 2 <= n <= MAX_SAMPLES or not 1 <= estimators <= MAX_ESTIMATORS:
        return INVALID_RESULT
    if not 1 <= learning_micro <= 1_000_000 or len(values) != 4 + 2 * n:
        return INVALID_RESULT
    xs, ys_milli = values[4:4+n], values[4+n:]
    if (any(x < -1000 or x > 1000 for x in xs)
            or any(xs[i-1] >= xs[i] for i in range(1, n))
            or not -1000 <= query <= 1000
            or any(y < -1_000_000 or y > 1_000_000 for y in ys_milli)):
        return INVALID_RESULT

    x_values = [float(x) for x in xs]
    y_values = [y / 1000.0 for y in ys_milli]
    rate = learning_micro / 1_000_000.0
    initial = sum(y_values) / n
    predictions = [initial] * n
    query_prediction = initial
    for _ in range(estimators):
        residuals = [y_values[i] - predictions[i] for i in range(n)]
        best_error = math.inf
        best_split = -1
        best_left = best_right = 0.0
        if any(value != residuals[0] for value in residuals[1:]):
            for split in range(n - 1):
                threshold = (x_values[split] + x_values[split + 1]) / 2.0
                left_count = split + 1
                right_count = n - left_count
                left_mean = sum(residuals[:left_count]) / left_count
                right_mean = sum(residuals[left_count:]) / right_count
                error = sum((v - left_mean) ** 2 for v in residuals[:left_count])
                error += sum((v - right_mean) ** 2 for v in residuals[left_count:])
                if error < best_error:
                    best_error, best_split = error, split
                    best_left, best_right = left_mean, right_mean
        if best_split < 0:
            leaf = sum(residuals) / n
            predictions = [value + rate * leaf for value in predictions]
            query_prediction += rate * leaf
        else:
            threshold = (x_values[best_split] + x_values[best_split + 1]) / 2.0
            for i, x in enumerate(x_values):
                predictions[i] += rate * (best_left if x <= threshold else best_right)
            query_prediction += rate * (best_left if query <= threshold else best_right)
    return query_prediction
