"""Reference implementation for the bounded greedy vertex-cover heuristic."""

from __future__ import annotations

MAX_VERTICES = 16
MAX_INPUT_LENGTH = MAX_VERTICES + 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    vertex_count = values[0]
    if not 1 <= vertex_count <= MAX_VERTICES or len(values) != vertex_count + 1:
        return -1
    limit = (1 << vertex_count) - 1
    neighbors = list(values[1:])
    if any(mask < 0 or mask & ~limit for mask in neighbors):
        return -1
    for vertex, mask in enumerate(neighbors):
        if mask & (1 << vertex):
            return -1
        for other in range(vertex_count):
            if bool(mask & (1 << other)) != bool(neighbors[other] & (1 << vertex)):
                return -1

    chosen = 0
    while True:
        best_vertex = -1
        best_degree = 0
        for vertex, mask in enumerate(neighbors):
            degree = 0
            remaining = mask
            while remaining:
                remaining &= remaining - 1
                degree += 1
            if degree > best_degree:
                best_vertex, best_degree = vertex, degree
        if best_vertex < 0:
            return chosen
        chosen |= 1 << best_vertex
        removed_bit = 1 << best_vertex
        for vertex in range(vertex_count):
            neighbors[vertex] &= ~removed_bit
        neighbors[best_vertex] = 0
