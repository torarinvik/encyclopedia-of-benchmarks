"""Primary ABI oracle for one linear-kernel SMO dual pair update."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_SAMPLES = 2
MAX_SAMPLES = 8
MIN_FEATURES = 1
MAX_FEATURES = 3
MAX_C_MILLI = 5000
MAX_ABS_BIAS_MILLI = 1_000_000
FEATURE_LIMIT = 32
MAX_VALID_INPUT_LENGTH = 6 + 2 * MAX_SAMPLES + MAX_SAMPLES * MAX_FEATURES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_SAMPLES + 1
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _decode(values: Sequence[int | float] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    decoded: list[int] = []
    for value in values:
        if (type(value) not in (int, float) or not math.isfinite(float(value))
                or not float(value).is_integer()):
            return None
        decoded.append(int(value))
    if len(decoded) < 6:
        return None
    n, d, c_milli, bias_milli = decoded[:4]
    if (not MIN_SAMPLES <= n <= MAX_SAMPLES
            or not MIN_FEATURES <= d <= MAX_FEATURES
            or not 1 <= c_milli <= MAX_C_MILLI
            or abs(bias_milli) > MAX_ABS_BIAS_MILLI
            or len(decoded) != 6 + 2 * n + n * d):
        return None
    labels = decoded[4:4 + n]
    if any(label not in (-1, 1) for label in labels) or len(set(labels)) != 2:
        return None
    alpha_begin = 4 + n
    alpha_milli = decoded[alpha_begin:alpha_begin + n]
    if (any(alpha < 0 or alpha > c_milli for alpha in alpha_milli)
            or sum(label * alpha for label, alpha in zip(labels, alpha_milli)) != 0):
        return None
    feature_begin = alpha_begin + n
    flat = decoded[feature_begin:feature_begin + n * d]
    if any(abs(value) > FEATURE_LIMIT for value in flat):
        return None
    features = tuple(tuple(float(flat[row * d + col]) for col in range(d))
                     for row in range(n))
    pair_begin = feature_begin + n * d
    i, j = decoded[pair_begin:pair_begin + 2]
    if not (0 <= i < n and 0 <= j < n and i != j):
        return None
    return (n, d, c_milli / 1000.0, bias_milli / 1000.0,
            tuple(labels), tuple(alpha / 1000.0 for alpha in alpha_milli),
            features, i, j)


def _dot(left: Sequence[float], right: Sequence[float]) -> float:
    return sum(a * b for a, b in zip(left, right))


def _dual_objective(alpha: Sequence[float], labels: Sequence[int],
                    features: Sequence[Sequence[float]]) -> float:
    linear = sum(alpha[k] for k in range(len(alpha)))
    quadratic = 0.0
    for row in range(len(alpha)):
        for col in range(len(alpha)):
            quadratic += (alpha[row] * alpha[col] * labels[row] * labels[col]
                          * _dot(features[row], features[col]))
    return linear - 0.5 * quadratic


def _update(parsed) -> tuple[float, ...]:
    n, _d, c_value, bias, labels, alpha, features, i, j = parsed
    yi, yj = labels[i], labels[j]
    old_i, old_j = alpha[i], alpha[j]
    kii = _dot(features[i], features[i])
    kjj = _dot(features[j], features[j])
    kij = _dot(features[i], features[j])
    errors = []
    for target in (i, j):
        prediction = bias + sum(
            alpha[k] * labels[k] * _dot(features[k], features[target])
            for k in range(n)
        )
        errors.append(prediction - labels[target])
    error_i, error_j = errors

    if yi != yj:
        low = max(0.0, old_j - old_i)
        high = min(c_value, c_value + old_j - old_i)
    else:
        low = max(0.0, old_i + old_j - c_value)
        high = min(c_value, old_i + old_j)

    eta = 2.0 * kij - kii - kjj
    if eta < 0.0:
        new_j = old_j - yj * (error_i - error_j) / eta
        new_j = min(high, max(low, new_j))
    else:
        # A zero-curvature pair can occur for duplicate feature vectors.
        # Compare the two feasible endpoints and choose the lower on a tie.
        endpoint_scores: list[tuple[float, float]] = []
        sign = yi * yj
        for candidate_j in (low, high):
            candidate_i = old_i + sign * (old_j - candidate_j)
            candidate = list(alpha)
            candidate[i], candidate[j] = candidate_i, candidate_j
            endpoint_scores.append((_dual_objective(candidate, labels, features), candidate_j))
        new_j = max(endpoint_scores, key=lambda item: (item[0], -item[1]))[1]

    sign = yi * yj
    new_i = old_i + sign * (old_j - new_j)
    delta_i, delta_j = new_i - old_i, new_j - old_j
    b1 = (bias - error_i - yi * delta_i * kii - yj * delta_j * kij)
    b2 = (bias - error_j - yi * delta_i * kij - yj * delta_j * kjj)
    if 0.0 < new_i < c_value:
        new_bias = b1
    elif 0.0 < new_j < c_value:
        new_bias = b2
    else:
        new_bias = (b1 + b2) * 0.5
    result = list(alpha)
    result[i], result[j] = new_i, new_j
    result.append(new_bias)
    return tuple(result)


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    """Compute the ABI result, validating input before output capacity."""
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if (type(output_capacity) is not int or output_capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, ()
    if output_is_null or output_capacity < parsed[0] + 1:
        return OUTPUT_ERROR, ()
    result = _update(parsed)
    return (len(result), result) if all(math.isfinite(x) for x in result) else (INVALID_RESULT, ())
