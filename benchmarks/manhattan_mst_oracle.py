"""Kruskal reference oracle for the bounded complete Manhattan metric MST."""

from __future__ import annotations

from collections.abc import Sequence

MAX_POINTS = 32
MAX_COORDINATE = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS
INVALID_RESULT = -1


def expected_output(values: Sequence[int] | None) -> int:
    """Return the MST weight, using Kruskal on all implicit metric edges."""
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT

    point_count = values[0]
    if (not 1 <= point_count <= MAX_POINTS
            or len(values) != 1 + 2 * point_count):
        return INVALID_RESULT
    points: list[tuple[int, int]] = []
    for index in range(point_count):
        x = values[1 + 2 * index]
        y = values[2 + 2 * index]
        if (not -MAX_COORDINATE <= x <= MAX_COORDINATE
                or not -MAX_COORDINATE <= y <= MAX_COORDINATE):
            return INVALID_RESULT
        points.append((x, y))

    edges = sorted(
        (abs(x1 - x2) + abs(y1 - y2), first, second)
        for first, (x1, y1) in enumerate(points)
        for second, (x2, y2) in enumerate(points[first + 1:], start=first + 1)
    )
    parent = list(range(point_count))
    sizes = [1] * point_count

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    total = 0
    accepted = 0
    for weight, first, second in edges:
        first_root = find(first)
        second_root = find(second)
        if first_root == second_root:
            continue
        if sizes[first_root] < sizes[second_root]:
            first_root, second_root = second_root, first_root
        parent[second_root] = first_root
        sizes[first_root] += sizes[second_root]
        total += weight
        accepted += 1
        if accepted == point_count - 1:
            break
    return total
