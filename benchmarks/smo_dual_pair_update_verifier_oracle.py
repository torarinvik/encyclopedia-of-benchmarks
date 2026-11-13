"""Independent direct-objective verifier for one SMO dual pair update."""

from __future__ import annotations

import math
from collections.abc import Sequence

from smo_dual_pair_update_oracle import (
    INVALID_RESULT,
    OUTPUT_ERROR,
    MAX_OUTPUT_ELEMENTS,
    _decode,
)


def _dot(a: Sequence[float], b: Sequence[float]) -> float:
    return sum(x * y for x, y in zip(a, b))


def _objective(alpha: Sequence[float], labels: Sequence[int],
               features: Sequence[Sequence[float]]) -> float:
    value = sum(alpha)
    for p in range(len(alpha)):
        for q in range(len(alpha)):
            value -= 0.5 * alpha[p] * alpha[q] * labels[p] * labels[q] * _dot(features[p], features[q])
    return value


def _solve(parsed) -> tuple[float, ...]:
    n, _d, c_value, bias, labels, alpha, features, i, j = parsed
    yi, yj = labels[i], labels[j]
    old_i, old_j = alpha[i], alpha[j]
    sign = yi * yj
    if yi != yj:
        low = max(0.0, old_j - old_i)
        high = min(c_value, c_value + old_j - old_i)
    else:
        low = max(0.0, old_i + old_j - c_value)
        high = min(c_value, old_i + old_j)

    # Restricting the full dual objective to the equality-preserving line gives
    # a concave quadratic. Find its stationary point from the directional
    # derivative, then choose the best feasible candidate by evaluating the
    # original objective directly.
    grad_i = 1.0 - yi * sum(
        alpha[k] * labels[k] * _dot(features[k], features[i]) for k in range(n)
    )
    grad_j = 1.0 - yj * sum(
        alpha[k] * labels[k] * _dot(features[k], features[j]) for k in range(n)
    )
    direction_slope = grad_j - sign * grad_i
    distance_squared = sum(
        (features[i][r] - features[j][r]) ** 2
        for r in range(len(features[i]))
    )
    candidates = [low]
    stationary = None
    if distance_squared > 0.0:
        stationary = old_j + direction_slope / distance_squared
        if low <= stationary <= high:
            candidates.append(stationary)
    if high != low:
        candidates.append(high)
    candidates = sorted(set(candidates))

    chosen_j = candidates[0]
    chosen_score = -math.inf
    for candidate_j in candidates:
        candidate_i = old_i + sign * (old_j - candidate_j)
        candidate_alpha = list(alpha)
        candidate_alpha[i], candidate_alpha[j] = candidate_i, candidate_j
        score = _objective(candidate_alpha, labels, features)
        if score > chosen_score:
            chosen_score, chosen_j = score, candidate_j

    new_i = old_i + sign * (old_j - chosen_j)
    delta_i, delta_j = new_i - old_i, chosen_j - old_j
    kii = _dot(features[i], features[i])
    kjj = _dot(features[j], features[j])
    kij = _dot(features[i], features[j])
    error_i = bias + sum(
        alpha[k] * labels[k] * _dot(features[k], features[i]) for k in range(n)
    ) - yi
    error_j = bias + sum(
        alpha[k] * labels[k] * _dot(features[k], features[j]) for k in range(n)
    ) - yj
    bias_i = bias - error_i - yi * delta_i * kii - yj * delta_j * kij
    bias_j = bias - error_j - yi * delta_i * kij - yj * delta_j * kjj
    c_value = parsed[2]
    if 0.0 < new_i < c_value:
        new_bias = bias_i
    elif 0.0 < chosen_j < c_value:
        new_bias = bias_j
    else:
        new_bias = (bias_i + bias_j) * 0.5
    result = list(alpha)
    result[i], result[j] = new_i, chosen_j
    result.append(new_bias)
    return tuple(result)


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if (type(output_capacity) is not int or output_capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, ()
    if output_is_null or output_capacity < parsed[0] + 1:
        return OUTPUT_ERROR, ()
    result = _solve(parsed)
    return (len(result), result) if all(math.isfinite(x) for x in result) else (INVALID_RESULT, ())
