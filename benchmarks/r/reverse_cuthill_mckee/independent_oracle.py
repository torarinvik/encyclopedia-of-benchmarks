"""Adjacency-matrix/queue reference for bounded RCM fixtures."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_INPUT_LENGTH = 59


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[list[bool]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, edge_count = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= edge_count <= n * (n - 1) // 2:
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    matrix = [[False] * n for _ in range(n)]
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left < n or not 0 <= right < n or left == right:
            return None
        if matrix[left][right]:
            return None
        matrix[left][right] = matrix[right][left] = True
    return n, matrix


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, matrix = decoded
    degrees = [sum(row) for row in matrix]
    remaining = set(range(n))
    permutation: list[int] = []
    while remaining:
        root = min(remaining, key=lambda vertex: (degrees[vertex], vertex))
        queue = [root]
        component: list[int] = []
        discovered = {root}
        remaining.remove(root)
        cursor = 0
        while cursor < len(queue):
            vertex = queue[cursor]
            cursor += 1
            component.append(vertex)
            neighbors = [candidate for candidate in range(n)
                         if matrix[vertex][candidate] and candidate in remaining]
            neighbors.sort(key=lambda candidate: (degrees[candidate], candidate))
            for candidate in neighbors:
                remaining.remove(candidate)
                discovered.add(candidate)
                queue.append(candidate)
        if len(discovered) != len(component):
            return -1
        permutation.extend(component)
    permutation.reverse()

    positions = {vertex: rank for rank, vertex in enumerate(permutation)}
    bandwidth = 0
    for left in range(n):
        for right in range(left + 1, n):
            if matrix[left][right]:
                bandwidth = max(bandwidth, abs(positions[left] - positions[right]))
    packed = sum(vertex << (3 * rank) for rank, vertex in enumerate(permutation))
    return (bandwidth << 24) | packed
