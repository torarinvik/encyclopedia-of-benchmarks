"""Deterministic source-order oracle for the bounded raw R K-means contract."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_ROWS = 32
MAX_DIMENSIONS = 4
MAX_CLUSTERS = 8
MAX_ITERATIONS = 64
MAX_COORDINATE = 64
MAX_PARSEABLE_INPUT_LENGTH = 144


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return one selected final center, distance, or zero-based assignment.

    Input is ``[rows, dimensions, k, iteration_limit, init_rows..., data...,
    field, arg0, arg1]``. Initial row indices are explicit to remove R's RNG
    from the comparison contract while retaining its sample-without-replacement
    starting-center behavior.
    """
    if not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if len(values) < 4 or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                              for value in values):
        return INVALID_RESULT

    rows, dimensions, k, iteration_limit = values[:4]
    if not 2 <= rows <= MAX_ROWS or not 2 <= dimensions <= MAX_DIMENSIONS:
        return INVALID_RESULT
    if not 1 <= k <= min(MAX_CLUSTERS, rows // 2):
        return INVALID_RESULT
    if not 1 <= iteration_limit <= MAX_ITERATIONS:
        return INVALID_RESULT
    data_count = rows * dimensions
    expected_length = 4 + k + data_count + 3
    if len(values) != expected_length:
        return INVALID_RESULT

    initial_rows = values[4:4 + k]
    if (len(set(initial_rows)) != k
            or any(not 0 <= index < rows for index in initial_rows)):
        return INVALID_RESULT
    data_start = 4 + k
    data_words = values[data_start:data_start + data_count]
    if any(not -MAX_COORDINATE <= value <= MAX_COORDINATE for value in data_words):
        return INVALID_RESULT
    data = [
        [float(data_words[row * dimensions + column]) for column in range(dimensions)]
        for row in range(rows)
    ]

    selector_start = data_start + data_count
    field, arg0, arg1 = values[selector_start:selector_start + 3]
    if field not in (0, 1, 2):
        return INVALID_RESULT
    if field == 0:
        if not 0 <= arg0 < k or not 0 <= arg1 < dimensions:
            return INVALID_RESULT
    elif field == 1:
        if not 0 <= arg0 < rows or not 0 <= arg1 < k:
            return INVALID_RESULT
    elif not 0 <= arg0 < rows or arg1 != 0:
        return INVALID_RESULT

    centers = [data[index].copy() for index in initial_rows]
    final_distances: list[list[float]] | None = None
    final_assignments: list[int] | None = None
    for _ in range(iteration_limit):
        distances: list[list[float]] = []
        assignments: list[int] = []
        members: list[list[int]] = [[] for _ in range(k)]
        for row in range(rows):
            row_distances = []
            for cluster in range(k):
                squared_distance = 0.0
                for dimension in range(dimensions):
                    difference = data[row][dimension] - centers[cluster][dimension]
                    squared_distance += difference * difference
                row_distances.append(math.sqrt(squared_distance))
            distances.append(row_distances)
            winner = 0
            for cluster in range(1, k):
                if row_distances[cluster] < row_distances[winner]:
                    winner = cluster
            assignments.append(winner)
            members[winner].append(row)

        if any(len(cluster_rows) < 2 for cluster_rows in members):
            return INVALID_RESULT

        updated: list[list[float]] = []
        for cluster_rows in members:
            center = []
            for dimension in range(dimensions):
                total = 0.0
                for row in cluster_rows:
                    total += data[row][dimension]
                center.append(total / len(cluster_rows))
            updated.append(center)

        stable = all(
            centers[cluster][dimension] == updated[cluster][dimension]
            for cluster in range(k)
            for dimension in range(dimensions)
        )
        centers = updated
        if stable:
            final_distances = distances
            final_assignments = assignments
            break

    if final_distances is None or final_assignments is None:
        return INVALID_RESULT
    if field == 0:
        return centers[arg0][arg1]
    if field == 1:
        return final_distances[arg0][arg1]
    return float(final_assignments[arg0])
