"""Reference output for bounded one-dimensional Gaussian-mixture EM."""

from __future__ import annotations

import math

MAX_SAMPLES = 16
MAX_ITERATIONS = 20
MAX_INPUT_LENGTH = 3 + MAX_SAMPLES
MAX_OUTPUT_BYTES = MAX_SAMPLES + 1
REGULARIZATION = 1e-6
PI = math.pi


def _pdf(value: float, mean: float, variance: float) -> float:
    return math.exp(-((value - mean) ** 2) / (2.0 * variance)) / math.sqrt(2.0 * PI * variance)


def _responsibilities(data: list[float], weights: list[float], means: list[float],
                      variances: list[float]) -> list[tuple[float, float]] | None:
    result = []
    for value in data:
        probability0 = weights[0] * _pdf(value, means[0], variances[0])
        probability1 = weights[1] * _pdf(value, means[1], variances[1])
        total = probability0 + probability1
        if total == 0.0 or not math.isfinite(total):
            return None
        result.append((probability0 / total, probability1 / total))
    return result


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    sample_count, max_iterations, tolerance_micro = values[:3]
    if (not 2 <= sample_count <= MAX_SAMPLES
            or not 1 <= max_iterations <= MAX_ITERATIONS
            or not 1 <= tolerance_micro <= 1000
            or len(values) != 3 + sample_count):
        return -1, b""
    samples_milli = values[3:]
    if (any(not -5000 <= sample <= 5000 for sample in samples_milli)
            or any(samples_milli[index - 1] > samples_milli[index]
                   for index in range(1, sample_count))):
        return -1, b""

    data = [sample / 1000.0 for sample in samples_milli]
    data_mean = sum(data) / sample_count
    covariance = (sum((value - data_mean) ** 2 for value in data) / (sample_count - 1)
                  + REGULARIZATION)
    weights = [0.5, 0.5]
    means = [data[0], data[-1]]
    variances = [covariance, covariance]
    tolerance = tolerance_micro / 1_000_000.0
    previous_likelihood: float | None = None
    iterations = 0

    for iteration in range(max_iterations):
        responsibilities = _responsibilities(data, weights, means, variances)
        if responsibilities is None:
            return -1, b""

        counts = [sum(row[component] for row in responsibilities) for component in range(2)]
        if any(count <= 0.0 or not math.isfinite(count) for count in counts):
            return -1, b""
        weights = [count / sample_count for count in counts]
        means = [sum(responsibilities[index][component] * data[index]
                     for index in range(sample_count)) / counts[component]
                 for component in range(2)]
        variances = [
            sum(responsibilities[index][component] * (data[index] - means[component]) ** 2
                for index in range(sample_count)) / counts[component] + REGULARIZATION
            for component in range(2)
        ]

        likelihood = 0.0
        for value in data:
            density = (weights[0] * _pdf(value, means[0], variances[0])
                       + weights[1] * _pdf(value, means[1], variances[1]))
            likelihood += math.log(density + 1e-12)
        iterations = iteration + 1
        if (previous_likelihood is not None
                and abs(likelihood - previous_likelihood) < tolerance):
            break
        previous_likelihood = likelihood

    responsibilities = _responsibilities(data, weights, means, variances)
    if responsibilities is None:
        return -1, b""
    labels = [0 if row[0] >= row[1] else 1 for row in responsibilities]
    output = bytes([iterations, *labels])
    return len(output), output
