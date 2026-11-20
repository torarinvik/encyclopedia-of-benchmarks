"""Bounded Reverse Cuthill-McKee graph ordering reference."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 1
MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (MAX_VERTICES - 1) * (1 << 24) + ((1 << (3 * MAX_VERTICES)) - 1)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, edge_count = values[0], values[1]
    if (not MIN_VERTICES <= n <= MAX_VERTICES
            or not 0 <= edge_count <= n * (n - 1) // 2
            or len(values) != 2 + 2 * edge_count):
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for position in range(edge_count):
        left, right = values[2 + 2 * position:4 + 2 * position]
        if not 0 <= left < n or not 0 <= right < n or left == right:
            return None
        edge = (min(left, right), max(left, right))
        if edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return n, edges


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, edges = parsed
    adjacency = [0] * n
    for left, right in edges:
        adjacency[left] |= 1 << right
        adjacency[right] |= 1 << left
    degree = [neighbors.bit_count() for neighbors in adjacency]

    unvisited = (1 << n) - 1
    order: list[int] = []
    while unvisited:
        root = min((vertex for vertex in range(n) if unvisited & (1 << vertex)),
                   key=lambda vertex: (degree[vertex], vertex))
        component = [root]
        queue = [root]
        unvisited &= ~(1 << root)
        head = 0
        while head < len(queue):
            vertex = queue[head]
            head += 1
            fresh = [neighbor for neighbor in range(n)
                     if adjacency[vertex] & (1 << neighbor)
                     and unvisited & (1 << neighbor)]
            fresh.sort(key=lambda neighbor: (degree[neighbor], neighbor))
            for neighbor in fresh:
                unvisited &= ~(1 << neighbor)
                queue.append(neighbor)
                component.append(neighbor)
        order.extend(component)
    order.reverse()

    position = [0] * n
    rank_word = 0
    for rank, vertex in enumerate(order):
        position[vertex] = rank
        rank_word |= vertex << (3 * rank)
    bandwidth = max((abs(position[left] - position[right]) for left, right in edges),
                    default=0)
    return (bandwidth << 24) | rank_word
