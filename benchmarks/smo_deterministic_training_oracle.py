"""Primary reference for a bounded deterministic Platt SMO training trace."""

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
MAX_PASSES = 16
FEATURE_LIMIT = 32
MAX_VALID_INPUT_LENGTH = 4 + MAX_SAMPLES + MAX_SAMPLES * MAX_FEATURES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_SAMPLES + 4
WORKSPACE_BYTES = 4096
SMO_TOLERANCE = 1e-3
SMO_EPSILON = 1e-3
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _integer(value: int | float) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        converted = float(value)
    except (OverflowError, ValueError):
        return False
    return math.isfinite(converted) and converted.is_integer()


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
    if not all(_integer(value) for value in values):
        return None
    data = tuple(int(value) for value in values)
    if len(data) < 4:
        return None
    n, d, c_milli, pass_cap = data[:4]
    if (not MIN_SAMPLES <= n <= MAX_SAMPLES
            or not MIN_FEATURES <= d <= MAX_FEATURES
            or not 1 <= c_milli <= MAX_C_MILLI
            or not 1 <= pass_cap <= MAX_PASSES
            or len(data) != 4 + n + n * d):
        return None
    labels = data[4:4 + n]
    if any(label not in (-1, 1) for label in labels) or len(set(labels)) != 2:
        return None
    flat = data[4 + n:]
    if any(abs(value) > FEATURE_LIMIT for value in flat):
        return None
    points = tuple(tuple(float(flat[row * d + col]) for col in range(d))
                   for row in range(n))
    return n, d, c_milli / 1000.0, pass_cap, tuple(labels), points


def _dot(a: Sequence[float], b: Sequence[float]) -> float:
    return sum(x * y for x, y in zip(a, b))


def _score(index: int, alpha: Sequence[float], bias: float,
           labels: Sequence[int], points: Sequence[Sequence[float]]) -> float:
    return bias + sum(alpha[k] * labels[k] * _dot(points[k], points[index])
                      for k in range(len(alpha)))


def _dual(alpha: Sequence[float], labels: Sequence[int],
          points: Sequence[Sequence[float]]) -> float:
    value = sum(alpha)
    for p in range(len(alpha)):
        for q in range(len(alpha)):
            value -= (0.5 * alpha[p] * alpha[q] * labels[p] * labels[q]
                      * _dot(points[p], points[q]))
    return value


def _take_step(i: int, j: int, alpha: list[float], bias: float, c: float,
               labels: Sequence[int], points: Sequence[Sequence[float]]) -> tuple[bool, float]:
    if i == j:
        return False, bias
    yi, yj = labels[i], labels[j]
    old_i, old_j = alpha[i], alpha[j]
    error_i = _score(i, alpha, bias, labels, points) - yi
    error_j = _score(j, alpha, bias, labels, points) - yj
    if yi != yj:
        low = max(0.0, old_j - old_i)
        high = min(c, c + old_j - old_i)
    else:
        low = max(0.0, old_i + old_j - c)
        high = min(c, old_i + old_j)
    if low == high:
        return False, bias

    kii = _dot(points[i], points[i])
    kjj = _dot(points[j], points[j])
    kij = _dot(points[i], points[j])
    curvature = kii + kjj - 2.0 * kij
    if curvature > 0.0:
        new_j = old_j + yj * (error_i - error_j) / curvature
        new_j = min(high, max(low, new_j))
    else:
        # Primary uses the source's endpoint comparison, evaluated directly
        # from the full dual objective to avoid a separate endpoint formula.
        sign = yi * yj
        endpoints = []
        for candidate_j in (low, high):
            candidate_i = old_i + sign * (old_j - candidate_j)
            candidate = list(alpha)
            candidate[i], candidate[j] = candidate_i, candidate_j
            endpoints.append((_dual(candidate, labels, points), candidate_j))
        if endpoints[0][0] > endpoints[1][0] + SMO_EPSILON:
            new_j = endpoints[0][1]
        elif endpoints[1][0] > endpoints[0][0] + SMO_EPSILON:
            new_j = endpoints[1][1]
        else:
            new_j = old_j
    if abs(new_j - old_j) < SMO_EPSILON * (new_j + old_j + SMO_EPSILON):
        return False, bias

    sign = yi * yj
    new_i = old_i + sign * (old_j - new_j)
    delta_i, delta_j = new_i - old_i, new_j - old_j
    bias_i = bias - error_i - yi * delta_i * kii - yj * delta_j * kij
    bias_j = bias - error_j - yi * delta_i * kij - yj * delta_j * kjj
    if 0.0 < new_i < c:
        new_bias = bias_i
    elif 0.0 < new_j < c:
        new_bias = bias_j
    else:
        new_bias = (bias_i + bias_j) * 0.5
    alpha[i], alpha[j] = new_i, new_j
    return True, new_bias


def _run(parsed) -> tuple[float, ...]:
    n, _d, c, pass_cap, labels, points = parsed
    alpha = [0.0] * n
    bias = 0.0
    changed = 0
    examine_all = True
    passes = 0
    while passes < pass_cap and (changed > 0 or examine_all):
        changed = 0
        if examine_all:
            indices = range(n)
        else:
            indices = (i for i in range(n) if 0.0 < alpha[i] < c)
        for j in indices:
            error_j = _score(j, alpha, bias, labels, points) - labels[j]
            r2 = error_j * labels[j]
            if not ((r2 < -SMO_TOLERANCE and alpha[j] < c)
                    or (r2 > SMO_TOLERANCE and alpha[j] > 0.0)):
                continue
            free = [i for i in range(n) if 0.0 < alpha[i] < c]
            if len(free) > 1:
                best_i = min(free, key=lambda i: (-abs(
                    (_score(i, alpha, bias, labels, points) - labels[i]) - error_j), i))
                success, new_bias = _take_step(best_i, j, alpha, bias, c, labels, points)
                if success:
                    changed += 1
                    bias = new_bias
                    continue
            succeeded = False
            for i in free:
                success, new_bias = _take_step(i, j, alpha, bias, c, labels, points)
                if success:
                    changed += 1
                    bias = new_bias
                    succeeded = True
                    break
            if succeeded:
                continue
            for i in range(n):
                success, new_bias = _take_step(i, j, alpha, bias, c, labels, points)
                if success:
                    changed += 1
                    bias = new_bias
                    break
        passes += 1
        if examine_all:
            examine_all = False
        elif changed == 0:
            examine_all = True
    converged = int(passes < pass_cap and changed == 0 and not examine_all)
    return (float(passes), float(changed), float(converged),
            *alpha, bias)


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
    if output_is_null or output_capacity < parsed[0] + 4:
        return OUTPUT_ERROR, ()
    result = _run(parsed)
    if not all(math.isfinite(value) for value in result):
        return INVALID_RESULT, ()
    return len(result), result
