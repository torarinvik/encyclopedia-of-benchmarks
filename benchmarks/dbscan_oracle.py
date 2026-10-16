"""Bounded, deterministic DBSCAN oracle for integer-coordinate 2D data."""

from __future__ import annotations

INVALID_RESULT = -1
MAX_POINTS = 32
MAX_COORDINATE = 1_000_000
MAX_EPSILON = 2_000_000
MAX_INPUT_LENGTH = 3 + 2 * MAX_POINTS
MAX_OUTPUT_BYTES = MAX_POINTS


def expected_output(values: tuple[int, ...] | list[int], output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return INVALID_RESULT, b""
    n, epsilon, min_points = values[:3]
    if not 1 <= n <= MAX_POINTS or not 1 <= epsilon <= MAX_EPSILON or not 1 <= min_points <= n:
        return INVALID_RESULT, b""
    if len(values) != 3 + 2 * n or any(abs(v) > MAX_COORDINATE for v in values[3:]):
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_capacity is not None and output_capacity < n:
        return -2, b""

    points = [(values[3 + 2 * i], values[4 + 2 * i]) for i in range(n)]
    eps2 = epsilon * epsilon
    neighbors = [[j for j, q in enumerate(points)
                  if (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 <= eps2]
                 for p in points]
    labels = [-1] * n
    cluster = 0
    for i in range(n):
        if labels[i] != -1 or len(neighbors[i]) < min_points:
            continue
        labels[i] = cluster
        seeds = list(neighbors[i])
        queued = set(seeds)
        position = 0
        while position < len(seeds):
            q = seeds[position]
            position += 1
            if labels[q] >= 0 and labels[q] != cluster:
                continue
            labels[q] = cluster
            if len(neighbors[q]) >= min_points:
                for r in neighbors[q]:
                    if labels[r] == -1 and r not in queued:
                        seeds.append(r)
                        queued.add(r)
        cluster += 1
    return n, bytes(0 if label < 0 else label + 1 for label in labels)
