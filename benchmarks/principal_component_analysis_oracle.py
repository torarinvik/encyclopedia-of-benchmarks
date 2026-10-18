"""Oracle for the bounded pinned Rust principal-component-analysis routine."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_SAMPLES = 2
MAX_SAMPLES = 8
MIN_FEATURES = 2
MAX_FEATURES = 4
MAX_ABS_VALUE = 100.0
MAX_ITERATIONS = 1000
TOLERANCE = 1e-10
MIN_NORM = 1e-10
MAX_INPUT_LENGTH = 3 + MAX_SAMPLES * MAX_FEATURES
MAX_OUTPUT_LENGTH = 2 + MAX_SAMPLES * MAX_FEATURES
INVALID_RESULT = -1


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _power_iteration(matrix: list[float], n: int) -> tuple[float, list[float]] | None:
    """Mirror the pinned source's all-ones iteration and Rayleigh quotient."""
    vector = [1.0] * n
    previous = [0.0] * n
    converged = False
    for _ in range(MAX_ITERATIONS):
        previous = vector[:]
        next_vector = [0.0] * n
        for i in range(n):
            for j in range(n):
                next_vector[i] += matrix[i * n + j] * vector[j]
        norm = math.sqrt(sum(value * value for value in next_vector))
        if not math.isfinite(norm) or norm <= MIN_NORM:
            return None
        next_vector = [value / norm for value in next_vector]
        if not all(math.isfinite(value) for value in next_vector):
            return None
        vector = next_vector
        difference = max(abs(a - b) for a, b in zip(vector, previous))
        if difference < TOLERANCE:
            converged = True
            break
    if not converged:
        return None

    numerator = 0.0
    for i, value in enumerate(vector):
        row_sum = 0.0
        for j in range(n):
            row_sum += matrix[i * n + j] * vector[j]
        numerator += row_sum * value
    denominator = sum(value * value for value in vector)
    if not math.isfinite(numerator) or not math.isfinite(denominator) or denominator == 0.0:
        return None
    eigenvalue = numerator / denominator
    if not math.isfinite(eigenvalue):
        return None
    return eigenvalue, vector


def expected_result(values: Sequence[int | float] | None) -> list[float] | int:
    """Return source-ordered projected scores with shape header, or -1."""
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if not all(_finite_number(value) for value in values):
        return INVALID_RESULT
    if any(values[index] != int(values[index]) for index in range(3)):
        return INVALID_RESULT
    samples, features, components = map(int, values[:3])
    if not MIN_SAMPLES <= samples <= MAX_SAMPLES:
        return INVALID_RESULT
    if not MIN_FEATURES <= features <= MAX_FEATURES or not 1 <= components <= features:
        return INVALID_RESULT
    if len(values) != 3 + samples * features:
        return INVALID_RESULT
    raw = [float(value) for value in values[3:]]
    if any(abs(value) > MAX_ABS_VALUE for value in raw):
        return INVALID_RESULT

    rows = [raw[i * features:(i + 1) * features] for i in range(samples)]
    means = [0.0] * features
    for row in rows:
        for i, value in enumerate(row):
            means[i] += value
    for i in range(features):
        means[i] /= samples
    centered = [[value - means[i] for i, value in enumerate(row)] for row in rows]

    covariance = [0.0] * (features * features)
    for i in range(features):
        for j in range(i, features):
            cov = 0.0
            for row in centered:
                cov += row[i] * row[j]
            cov /= samples
            covariance[i * features + j] = cov
            covariance[j * features + i] = cov
    if not all(math.isfinite(value) for value in covariance):
        return INVALID_RESULT

    eigenvectors: list[list[float]] = []
    deflated = covariance[:]
    for _ in range(components):
        pair = _power_iteration(deflated, features)
        if pair is None:
            return INVALID_RESULT
        eigenvalue, vector = pair
        eigenvectors.append(vector)
        for i in range(features):
            for j in range(features):
                deflated[i * features + j] -= eigenvalue * vector[i] * vector[j]
        if not all(math.isfinite(value) for value in deflated):
            return INVALID_RESULT

    output = [float(samples), float(components)]
    for row in centered:
        for vector in eigenvectors:
            score = 0.0
            for ev, sample_value in zip(vector, row):
                score += ev * sample_value
            if not math.isfinite(score):
                return INVALID_RESULT
            output.append(score)
    return output
