"""Independent direct-dual reference for bounded deterministic SMO training."""

from __future__ import annotations

import math
from collections.abc import Sequence

from smo_deterministic_training_oracle import (
    ABSOLUTE_TOLERANCE,
    INVALID_RESULT,
    MAX_C_MILLI,
    MAX_OUTPUT_ELEMENTS,
    MAX_PASSES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_SAMPLES,
    OUTPUT_ERROR,
    SMO_EPSILON,
    SMO_TOLERANCE,
    WORKSPACE_BYTES,
)


def _decode(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or input_length > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    decoded = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            converted = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(converted) or not converted.is_integer():
            return None
        decoded.append(int(value))
    if len(decoded) < 4:
        return None
    n, d, c_milli, pass_cap = decoded[:4]
    if (not 2 <= n <= MAX_SAMPLES or not 1 <= d <= 3
            or not 1 <= c_milli <= MAX_C_MILLI
            or not 1 <= pass_cap <= MAX_PASSES
            or len(decoded) != 4 + n + n * d):
        return None
    labels = tuple(decoded[4:4 + n])
    if any(label not in (-1, 1) for label in labels) or len(set(labels)) != 2:
        return None
    flat = decoded[4 + n:]
    if any(abs(value) > 32 for value in flat):
        return None
    points = tuple(tuple(float(flat[row * d + col]) for col in range(d))
                   for row in range(n))
    return n, d, c_milli / 1000.0, pass_cap, labels, points


def _kernel(points, a, b):
    return sum(x * y for x, y in zip(points[a], points[b]))


def _dual(alpha, labels, points):
    total = sum(alpha)
    for i in range(len(alpha)):
        for j in range(len(alpha)):
            total -= (0.5 * alpha[i] * alpha[j] * labels[i] * labels[j]
                      * _kernel(points, i, j))
    return total


def _output_at(index, alpha, bias, labels, points):
    return bias + sum(alpha[k] * labels[k] * _kernel(points, k, index)
                      for k in range(len(alpha)))


def _step(i, j, alpha, bias, c, labels, points):
    if i == j:
        return False, bias
    old_i, old_j = alpha[i], alpha[j]
    yi, yj = labels[i], labels[j]
    error_i = _output_at(i, alpha, bias, labels, points) - yi
    error_j = _output_at(j, alpha, bias, labels, points) - yj
    if yi != yj:
        lo = max(0.0, old_j - old_i)
        hi = min(c, c + old_j - old_i)
    else:
        lo = max(0.0, old_i + old_j - c)
        hi = min(c, old_i + old_j)
    if lo == hi:
        return False, bias

    kii = _kernel(points, i, i)
    kjj = _kernel(points, j, j)
    kij = _kernel(points, i, j)
    curvature = kii + kjj - 2.0 * kij
    sign = yi * yj
    if curvature > 0.0:
        # Derive the stationary point from the gradient of the full dual.
        grad_i = 1.0 - yi * (_output_at(i, alpha, 0.0, labels, points))
        grad_j = 1.0 - yj * (_output_at(j, alpha, 0.0, labels, points))
        stationary = old_j + (grad_j - sign * grad_i) / curvature
        best = min(hi, max(lo, stationary))
    else:
        low_alpha = list(alpha)
        low_alpha[i] = old_i + sign * (old_j - lo)
        low_alpha[j] = lo
        high_alpha = list(alpha)
        high_alpha[i] = old_i + sign * (old_j - hi)
        high_alpha[j] = hi
        low_score = _dual(low_alpha, labels, points)
        high_score = _dual(high_alpha, labels, points)
        if low_score > high_score + SMO_EPSILON:
            best = lo
        elif high_score > low_score + SMO_EPSILON:
            best = hi
        else:
            best = old_j
    if abs(best - old_j) < SMO_EPSILON * (best + old_j + SMO_EPSILON):
        return False, bias

    new_i = old_i + sign * (old_j - best)
    di, dj = new_i - old_i, best - old_j
    b_i = bias - error_i - yi * di * kii - yj * dj * kij
    b_j = bias - error_j - yi * di * kij - yj * dj * kjj
    if 0.0 < new_i < c:
        updated_bias = b_i
    elif 0.0 < best < c:
        updated_bias = b_j
    else:
        updated_bias = 0.5 * (b_i + b_j)
    alpha[i], alpha[j] = new_i, best
    return True, updated_bias


def _replay(parsed):
    n, _d, c, cap, labels, points = parsed
    alpha = [0.0] * n
    bias = 0.0
    changed = 0
    all_examples = True
    pass_count = 0
    while pass_count < cap and (changed != 0 or all_examples):
        changed = 0
        for j in range(n):
            if not all_examples and not (0.0 < alpha[j] < c):
                continue
            error_j = _output_at(j, alpha, bias, labels, points) - labels[j]
            residual = labels[j] * error_j
            if not ((residual < -SMO_TOLERANCE and alpha[j] < c)
                    or (residual > SMO_TOLERANCE and alpha[j] > 0.0)):
                continue
            free = [i for i in range(n) if 0.0 < alpha[i] < c]
            if len(free) > 1:
                preferred = min(
                    free,
                    key=lambda i: (-abs(
                        _output_at(i, alpha, bias, labels, points) - labels[i] - error_j), i),
                )
                success, candidate_bias = _step(preferred, j, alpha, bias, c, labels, points)
                if success:
                    changed += 1
                    bias = candidate_bias
                    continue
            applied = False
            for i in free:
                success, candidate_bias = _step(i, j, alpha, bias, c, labels, points)
                if success:
                    changed += 1
                    bias = candidate_bias
                    applied = True
                    break
            if applied:
                continue
            for i in range(n):
                success, candidate_bias = _step(i, j, alpha, bias, c, labels, points)
                if success:
                    changed += 1
                    bias = candidate_bias
                    break
        pass_count += 1
        if all_examples:
            all_examples = False
        elif changed == 0:
            all_examples = True
    done = int(pass_count < cap and changed == 0 and not all_examples)
    return (float(pass_count), float(changed), float(done), *alpha, bias)


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
    result = _replay(parsed)
    if not all(math.isfinite(value) for value in result):
        return INVALID_RESULT, ()
    return len(result), result
