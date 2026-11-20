"""Independent direct all-pairs reference for active-set tree diameter."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_N = 32
MAX_OPERATIONS = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 1 + MAX_OPERATIONS + 1
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count, operation_count = values[0], values[1]
    if not 1 <= count <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != count + 1 + operation_count:
        return None
    parent = [-1] * count
    adjacency = [[] for _ in range(count)]
    for vertex in range(1, count):
        ancestor = values[vertex + 1]
        if not 0 <= ancestor < vertex:
            return None
        parent[vertex] = ancestor
        adjacency[vertex].append(ancestor)
        adjacency[ancestor].append(vertex)
    operations = list(values[count + 1:])
    if any(code != -1 and not 0 <= code < count for code in operations):
        return None
    return count, adjacency, operations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency, operations = parsed

    distances = [[0] * n for _ in range(n)]
    for source in range(n):
        distances[source] = [-1] * n
        distances[source][source] = 0
        queue = deque([source])
        while queue:
            vertex = queue.popleft()
            for neighbor in adjacency[vertex]:
                if distances[source][neighbor] < 0:
                    distances[source][neighbor] = distances[source][vertex] + 1
                    queue.append(neighbor)

    active = [False] * n
    checksum = 0
    query_number = 0
    for operation in operations:
        if operation >= 0:
            active[operation] = not active[operation]
            continue
        query_number += 1
        diameter = 0
        for left in range(n):
            if not active[left]:
                continue
            for right in range(left + 1, n):
                if active[right]:
                    diameter = max(diameter, distances[left][right])
        checksum += query_number * (diameter + 1)
    return checksum
