"""Oracle for the bounded two-feature slice of TheAlgorithms/R pca_algorithm."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_SAMPLES = 3
MAX_SAMPLES = 8
MAX_ABS_VALUE = 1_000.0
MIN_EIGENGAP = 1e-8
MAX_OUTPUT_ELEMENTS = MAX_SAMPLES + 4
INVALID_RESULT = -1


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return scores, the canonical leading component, and descending eigenvalues."""
    if not isinstance(values, (list, tuple)) or len(values) < 9:
        return None
    if any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values):
        return None
    if values[0] != int(values[0]) or values[1] != 2 or values[2] != 1:
        return None
    sample_count = int(values[0])
    if not MIN_SAMPLES <= sample_count <= MAX_SAMPLES or len(values) != 3 + 2 * sample_count:
        return None
    raw = [float(value) for value in values[3:]]
    if any(abs(value) > MAX_ABS_VALUE for value in raw):
        return None

    samples = [(raw[2 * i], raw[2 * i + 1]) for i in range(sample_count)]
    means = [sum(row[j] for row in samples) / sample_count for j in range(2)]
    centered = [[row[j] - means[j] for j in range(2)] for row in samples]
    denom = sample_count - 1
    variances = [sum(row[j] ** 2 for row in centered) / denom for j in range(2)]
    if any(variance <= 0.0 or not math.isfinite(variance) for variance in variances):
        return None
    scales = [math.sqrt(variance) for variance in variances]
    standardized = [[row[j] / scales[j] for j in range(2)] for row in centered]

    a = sum(row[0] * row[0] for row in standardized) / denom
    b = sum(row[0] * row[1] for row in standardized) / denom
    d = sum(row[1] * row[1] for row in standardized) / denom
    discriminant = math.sqrt((a - d) ** 2 + 4.0 * b * b)
    largest = 0.5 * (a + d + discriminant)
    smallest = 0.5 * (a + d - discriminant)
    if not math.isfinite(largest) or largest - smallest <= MIN_EIGENGAP:
        return None

    if b == 0.0:
        vector = [1.0, 0.0] if a >= d else [0.0, 1.0]
    else:
        vector = [b, largest - a]
        norm = math.hypot(vector[0], vector[1])
        if norm == 0.0 or not math.isfinite(norm):
            return None
        vector = [coordinate / norm for coordinate in vector]
    pivot = 0 if abs(vector[0]) >= abs(vector[1]) else 1
    if vector[pivot] < 0.0:
        vector = [-coordinate for coordinate in vector]

    scores = [row[0] * vector[0] + row[1] * vector[1] for row in standardized]
    return scores + vector + [largest, smallest]
