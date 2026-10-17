"""Oracle for TheAlgorithms/Java's BFS coloring on bounded undirected forests."""

from __future__ import annotations

from collections import deque

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_VERTICES = 0
MAX_VERTICES = 14
MIN_COLORS = 1
MAX_COLORS = 14
MAX_VALID_INPUT_LENGTH = MAX_VERTICES + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _valid_input(values: list[int] | tuple[int, ...]) -> tuple[int, int, list[int]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return None

    vertex_count, color_limit = values[:2]
    if not MIN_VERTICES <= vertex_count <= MAX_VERTICES:
        return None
    if not MIN_COLORS <= color_limit <= MAX_COLORS:
        return None
    if len(values) != vertex_count + 2:
        return None

    masks = list(values[2:])
    valid_mask = (1 << vertex_count) - 1
    if any(mask < 0 or mask & ~valid_mask for mask in masks):
        return None
    for vertex, mask in enumerate(masks):
        if mask & (1 << vertex):
            return None
        for neighbor in range(vertex_count):
            if bool(mask & (1 << neighbor)) != bool(masks[neighbor] & (1 << vertex)):
                return None

    # A disjoint-set check rejects every undirected cycle, including a cycle
    # confined to one component of an otherwise forest-shaped input.
    parent = list(range(vertex_count))

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for vertex, mask in enumerate(masks):
        for neighbor in range(vertex + 1, vertex_count):
            if mask & (1 << neighbor):
                root_a = find(vertex)
                root_b = find(neighbor)
                if root_a == root_b:
                    return None
                parent[root_a] = root_b

    return vertex_count, color_limit, masks


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return 1/0 for the pinned BFS source's forest result, or -1 if invalid."""
    parsed = _valid_input(values)
    if parsed is None:
        return INVALID_RESULT
    vertex_count, color_limit, masks = parsed

    colors = [1] * vertex_count
    visited = [False] * vertex_count
    maximum_color = 1
    for start in range(vertex_count):
        if visited[start]:
            continue
        visited[start] = True
        queue = deque([start])
        while queue:
            vertex = queue.popleft()
            for neighbor in range(vertex_count):
                if not masks[vertex] & (1 << neighbor):
                    continue
                if colors[vertex] == colors[neighbor]:
                    colors[neighbor] += 1
                maximum_color = max(maximum_color, colors[vertex], colors[neighbor])
                if maximum_color > color_limit:
                    return 0
                if not visited[neighbor]:
                    visited[neighbor] = True
                    queue.append(neighbor)

    return 1
