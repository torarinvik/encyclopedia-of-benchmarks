"""Centroid-based primary reference for the bounded active-set diameter trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_OPERATIONS = 64
MAX_VALID_INPUT_LENGTH = MAX_N + 1 + MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = 66_560
INVALID_RESULT = -1
MAX_LEVELS = 6


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, operation_count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != n + 1 + operation_count:
        return None
    parents = [-1] * n
    for vertex in range(1, n):
        parent = values[vertex + 1]
        if not 0 <= parent < vertex:
            return None
        parents[vertex] = parent
    operations = list(values[n + 1:])
    if any(operation != -1 and not 0 <= operation < n for operation in operations):
        return None
    return n, parents, operations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, parents, operations = parsed
    adjacency = [[] for _ in range(n)]
    for vertex in range(1, n):
        parent = parents[vertex]
        adjacency[parent].append(vertex)
        adjacency[vertex].append(parent)

    records: list[list[tuple[int, int, int]]] = [[] for _ in range(n)]
    blocked = [False] * n
    subtree_size = [0] * n

    def calculate_sizes(vertex: int, parent: int) -> int:
        subtree_size[vertex] = 1
        for neighbor in adjacency[vertex]:
            if neighbor != parent and not blocked[neighbor]:
                subtree_size[vertex] += calculate_sizes(neighbor, vertex)
        return subtree_size[vertex]

    def choose_centroid(vertex: int, parent: int, total: int) -> int:
        for neighbor in adjacency[vertex]:
            if (neighbor != parent and not blocked[neighbor]
                    and subtree_size[neighbor] > total // 2):
                return choose_centroid(neighbor, vertex, total)
        return vertex

    def record_component(centroid: int, vertex: int, parent: int,
                         distance: int, branch: int, level: int) -> None:
        if level >= MAX_LEVELS:
            return
        records[vertex].append((centroid, branch if vertex != centroid else n, distance))
        for neighbor in adjacency[vertex]:
            if neighbor != parent and not blocked[neighbor]:
                next_branch = neighbor if vertex == centroid else branch
                record_component(centroid, neighbor, vertex, distance + 1,
                                 next_branch, level)

    def decompose(entry: int, level: int) -> None:
        total = calculate_sizes(entry, -1)
        centroid = choose_centroid(entry, -1, total)
        record_component(centroid, centroid, -1, 0, n, level)
        blocked[centroid] = True
        for neighbor in adjacency[centroid]:
            if not blocked[neighbor]:
                decompose(neighbor, level + 1)

    decompose(0, 0)
    best = [[-1] * (n + 1) for _ in range(n)]
    active = [False] * n

    def recompute(centroid: int, branch: int) -> None:
        best[centroid][branch] = -1
        for vertex in range(n):
            if active[vertex]:
                for recorded_centroid, recorded_branch, distance in records[vertex]:
                    if recorded_centroid == centroid and recorded_branch == branch:
                        best[centroid][branch] = max(best[centroid][branch], distance)

    def diameter() -> int:
        answer = 0
        for centroid in range(n):
            first = second = -1
            for branch in range(n + 1):
                distance = best[centroid][branch]
                if distance > first:
                    first, second = distance, first
                elif distance > second:
                    second = distance
            if second >= 0:
                answer = max(answer, first + second)
        return answer

    checksum = 0
    query_number = 0
    for operation in operations:
        if operation == -1:
            query_number += 1
            checksum += query_number * (diameter() + 1)
            continue
        vertex = operation
        active[vertex] = not active[vertex]
        for centroid, branch, distance in records[vertex]:
            if active[vertex]:
                best[centroid][branch] = max(best[centroid][branch], distance)
            elif best[centroid][branch] == distance:
                recompute(centroid, branch)
    return checksum
