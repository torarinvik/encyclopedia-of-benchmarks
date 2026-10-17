"""Oracle for one bounded update of the pinned Python k-means implementation."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_POINT_COUNT = 1
MAX_POINT_COUNT = 16
MIN_DIMENSION = 1
MAX_DIMENSION = 4
MIN_CLUSTER_COUNT = 1
MAX_CLUSTER_COUNT = 4
MIN_COORDINATE = -16
MAX_COORDINATE = 16
MAX_VALID_INPUT_LENGTH = 3 + MAX_POINT_COUNT * MAX_DIMENSION + MAX_CLUSTER_COUNT * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_POINT_COUNT + MAX_CLUSTER_COUNT * MAX_DIMENSION
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _exact_integer(value: int | float) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


def _decode_input(values: Sequence[float] | None):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None

    point_count = _exact_integer(values[0])
    dimension = _exact_integer(values[1])
    cluster_count = _exact_integer(values[2])
    if point_count is None or dimension is None or cluster_count is None:
        return None
    if not MIN_POINT_COUNT <= point_count <= MAX_POINT_COUNT:
        return None
    if not MIN_DIMENSION <= dimension <= MAX_DIMENSION:
        return None
    if not MIN_CLUSTER_COUNT <= cluster_count <= min(MAX_CLUSTER_COUNT, point_count):
        return None

    expected_length = 3 + point_count * dimension + cluster_count * dimension
    if len(values) != expected_length:
        return None

    coordinates = [_exact_integer(value) for value in values[3:]]
    if any(value is None or not MIN_COORDINATE <= value <= MAX_COORDINATE for value in coordinates):
        return None

    data_flat = coordinates[: point_count * dimension]
    centroids_flat = coordinates[point_count * dimension :]
    data = [
        data_flat[row * dimension : (row + 1) * dimension]
        for row in range(point_count)
    ]
    centroids = [
        centroids_flat[row * dimension : (row + 1) * dimension]
        for row in range(cluster_count)
    ]
    return point_count, dimension, cluster_count, data, centroids


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return assignments and revised centroids, or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    point_count, dimension, cluster_count, data, centroids = decoded

    assignments: list[int] = []
    counts = [0] * cluster_count
    sums = [[0] * dimension for _ in range(cluster_count)]
    for row in data:
        best_cluster = 0
        best_distance = sum((row[column] - centroids[0][column]) ** 2 for column in range(dimension))
        for cluster in range(1, cluster_count):
            distance = sum(
                (row[column] - centroids[cluster][column]) ** 2
                for column in range(dimension)
            )
            if distance < best_distance:
                best_cluster = cluster
                best_distance = distance
        assignments.append(best_cluster)
        counts[best_cluster] += 1
        for column in range(dimension):
            sums[best_cluster][column] += row[column]

    if any(count == 0 for count in counts):
        return INVALID_RESULT, []

    output: list[float] = [float(cluster) for cluster in assignments]
    for cluster in range(cluster_count):
        output.extend(sums[cluster][column] / counts[cluster] for column in range(dimension))

    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
