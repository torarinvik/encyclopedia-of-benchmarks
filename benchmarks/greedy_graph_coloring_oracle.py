"""Oracle for bounded descending-degree greedy graph coloring."""

from __future__ import annotations

MAX_VERTICES = 14
MAX_INPUT_LENGTH = MAX_VERTICES + 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    vertex_count = values[0]
    if not 0 <= vertex_count <= MAX_VERTICES or len(values) != vertex_count + 1:
        return -1
    limit = (1 << vertex_count) - 1
    adjacency = list(values[1:])
    if any(mask < 0 or mask > limit for mask in adjacency):
        return -1
    for vertex, mask in enumerate(adjacency):
        if mask & (1 << vertex):
            return -1
        for other in range(vertex_count):
            if bool(mask & (1 << other)) != bool(adjacency[other] & (1 << vertex)):
                return -1

    def degree(mask: int) -> int:
        count = 0
        while mask:
            mask &= mask - 1
            count += 1
        return count

    order = sorted(range(vertex_count), key=lambda vertex: (-degree(adjacency[vertex]), vertex))
    colors = [0] * vertex_count
    color_count = 0
    for vertex in order:
        used = 0
        neighbor_mask = adjacency[vertex]
        for other in range(vertex_count):
            if neighbor_mask & (1 << other):
                used |= 1 << colors[other]
        color = 1
        while used & (1 << color):
            color += 1
        colors[vertex] = color
        color_count = max(color_count, color)

    packed = color_count
    for vertex, color in enumerate(colors):
        packed |= color << (4 * (vertex + 1))
    return packed
