"""Independent oracle for the bounded TheAlgorithms/Python mean-shift contract."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_POINT_COUNT = 1
MAX_POINT_COUNT = 16
MIN_DIMENSION = 1
MAX_DIMENSION = 3
MIN_COORDINATE = -10.0
MAX_COORDINATE = 10.0
MIN_BANDWIDTH = 0.5
MAX_BANDWIDTH = 20.0
MIN_ITERATIONS = 1
MAX_ITERATIONS = 64
MIN_TOLERANCE = 1.0e-5
MAX_TOLERANCE = 1.0e-2
THRESHOLD_MARGIN = 1.0e-6

MAX_VALID_INPUT_LENGTH = 5 + MAX_POINT_COUNT * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_ELEMENTS = MAX_POINT_COUNT
WORKSPACE_ELEMENTS = MAX_POINT_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR = -2


class _ThresholdMarginViolation(ValueError):
    """An executed decision distance falls too close to its threshold."""


def _euclidean_distance(point_a: Sequence[float], point_b: Sequence[float]) -> float:
    """Match the pinned source's sum-of-squares followed by ``** 0.5``."""
    return sum((a - b) ** 2 for a, b in zip(point_a, point_b)) ** 0.5


def _check_margin(distance: float, threshold: float) -> None:
    if abs(distance - threshold) < THRESHOLD_MARGIN:
        raise _ThresholdMarginViolation


def _mean_shift_labels(
    data: list[list[float]], bandwidth: float, max_iterations: int, tolerance: float
) -> list[int]:
    """Run the pinned update, greedy merge, and first-centroid tie behavior."""
    candidates = [point[:] for point in data]

    for _ in range(max_iterations):
        new_candidates: list[list[float]] = []
        for candidate in candidates:
            neighbors: list[list[float]] = []
            for point in data:
                distance = _euclidean_distance(point, candidate)
                _check_margin(distance, bandwidth)
                if distance <= bandwidth:
                    neighbors.append(point)
            if neighbors:
                new_candidates.append(
                    [
                        sum(point[dimension] for point in neighbors) / len(neighbors)
                        for dimension in range(len(candidate))
                    ]
                )
            else:
                new_candidates.append(candidate)

        all_converged = True
        for old, new in zip(candidates, new_candidates):
            movement = _euclidean_distance(old, new)
            _check_margin(movement, tolerance)
            if movement >= tolerance:
                # Match the source's generator passed to all(): later
                # convergence predicates are not evaluated after this point.
                all_converged = False
                break
        if all_converged:
            # The source breaks before assigning new_candidates to candidates.
            break
        candidates = new_candidates

    centroids: list[list[float]] = []
    for candidate in candidates:
        keep = True
        for existing in centroids:
            distance = _euclidean_distance(candidate, existing)
            _check_margin(distance, bandwidth)
            if distance < bandwidth:
                keep = False
                break
        if keep:
            centroids.append(candidate)

    labels: list[int] = []
    for point in data:
        # Match Python min's source-order key evaluation and first-key tie rule.
        best_index = 0
        best_distance = _euclidean_distance(point, centroids[best_index])
        for centroid_index in range(1, len(centroids)):
            distance = _euclidean_distance(point, centroids[centroid_index])
            if distance != best_distance and abs(distance - best_distance) < THRESHOLD_MARGIN:
                raise _ThresholdMarginViolation
            if distance < best_distance:
                best_index = centroid_index
                best_distance = distance
        labels.append(best_index)
    return labels


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return mean-shift labels or the reviewed float64 slice-I/O error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []
    if not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, []
    if any(type(value) not in (int, float) for value in values):
        return INVALID_RESULT, []

    try:
        numbers = [float(value) for value in values]
    except OverflowError:
        return INVALID_RESULT, []
    if any(not math.isfinite(value) for value in numbers):
        return INVALID_RESULT, []

    raw_point_count, raw_dimension, bandwidth, raw_iterations, tolerance = numbers[:5]
    if not raw_point_count.is_integer() or not raw_dimension.is_integer() or not raw_iterations.is_integer():
        return INVALID_RESULT, []
    point_count = int(raw_point_count)
    dimension = int(raw_dimension)
    max_iterations = int(raw_iterations)
    if not MIN_POINT_COUNT <= point_count <= MAX_POINT_COUNT:
        return INVALID_RESULT, []
    if not MIN_DIMENSION <= dimension <= MAX_DIMENSION:
        return INVALID_RESULT, []
    if not MIN_ITERATIONS <= max_iterations <= MAX_ITERATIONS:
        return INVALID_RESULT, []
    if not MIN_BANDWIDTH <= bandwidth <= MAX_BANDWIDTH:
        return INVALID_RESULT, []
    if not MIN_TOLERANCE <= tolerance <= MAX_TOLERANCE:
        return INVALID_RESULT, []
    if len(numbers) != 5 + point_count * dimension:
        return INVALID_RESULT, []

    coordinates = numbers[5:]
    if any(not MIN_COORDINATE <= value <= MAX_COORDINATE for value in coordinates):
        return INVALID_RESULT, []
    data = [
        coordinates[index * dimension : (index + 1) * dimension]
        for index in range(point_count)
    ]

    try:
        labels = _mean_shift_labels(data, bandwidth, max_iterations, tolerance)
    except _ThresholdMarginViolation:
        return INVALID_RESULT, []

    # Input validation, including every executed threshold decision, precedes
    # output-buffer validation, as required by the ABI contract.
    if output_is_null or (
        output_capacity is not None and output_capacity < point_count
    ):
        return OUTPUT_ERROR, []
    return point_count, [float(label) for label in labels]
