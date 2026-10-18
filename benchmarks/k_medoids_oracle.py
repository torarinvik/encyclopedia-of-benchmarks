"""Oracle for deterministic bounded k-medoids initialization and updates."""
from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_VALID_LENGTH = 15
MAX_PARSEABLE_LENGTH = 16
MAX_RESULT = (1 << 28) - 1


def expected_result(values: Sequence[int] | None) -> int:
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    point_count, medoid_count, max_iter = values[:3]
    if (not 2 <= point_count <= 8
            or not 1 <= medoid_count <= min(4, point_count)
            or not 1 <= max_iter <= 16
            or len(values) != 3 + medoid_count + point_count):
        return INVALID_RESULT

    initial_medoids = list(values[3:3 + medoid_count])
    points = list(values[3 + medoid_count:])
    if (any(not 0 <= index < point_count for index in initial_medoids)
            or len(set(initial_medoids)) != medoid_count
            or any(not -16 <= point <= 16 for point in points)
            or len(set(points)) != point_count):
        return INVALID_RESULT

    medoids = initial_medoids
    labels: list[int] = []
    for _ in range(max_iter):
        labels = []
        for point in points:
            best_slot = 0
            best_distance = abs(point - points[medoids[0]])
            for slot in range(1, medoid_count):
                distance = abs(point - points[medoids[slot]])
                if distance < best_distance:
                    best_slot = slot
                    best_distance = distance
            labels.append(best_slot)

        updated_medoids: list[int] = []
        for slot in range(medoid_count):
            cluster_points = [index for index, label in enumerate(labels) if label == slot]
            if not cluster_points:
                # Unique point values and distinct medoids guarantee this cannot occur.
                return INVALID_RESULT
            best_index = cluster_points[0]
            best_cost = sum(abs(points[best_index] - points[index]) for index in cluster_points)
            for candidate in cluster_points[1:]:
                cost = sum(abs(points[candidate] - points[index]) for index in cluster_points)
                if cost < best_cost:
                    best_index = candidate
                    best_cost = cost
            updated_medoids.append(best_index)

        if updated_medoids == medoids:
            break
        medoids = updated_medoids

    result = 0
    for slot, index in enumerate(medoids):
        result |= index << (3 * slot)
    for point_index, label in enumerate(labels):
        result |= label << (12 + 2 * point_index)
    if not 0 <= result <= MAX_RESULT:
        return INVALID_RESULT
    return result
