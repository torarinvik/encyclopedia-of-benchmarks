"""Independent adjacency-graph/BFS oracle for range unions."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_N = 32
MAX_Q = 32
MAX_PARSEABLE_INPUT_LENGTH = 99


def _decode(values: Sequence[int] | None):
    if values is None or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + 3 * q:
        return None
    operations = []
    for offset in range(2, len(values), 3):
        opcode, first, second = values[offset:offset + 3]
        if opcode == 0:
            if not 0 <= first <= second <= n:
                return None
        elif opcode == 1:
            if not (0 <= first < n and 0 <= second < n):
                return None
        elif opcode == 2:
            if not (0 <= first < n and second == 0):
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return n, operations


def _labels(adjacency: list[set[int]]) -> tuple[list[int], list[int]]:
    labels = [-1] * len(adjacency)
    sizes: list[int] = []
    for start in range(len(adjacency)):
        if labels[start] >= 0:
            continue
        component = len(sizes)
        labels[start] = component
        pending = deque([start])
        size = 0
        while pending:
            vertex = pending.popleft()
            size += 1
            for neighbor in adjacency[vertex]:
                if labels[neighbor] < 0:
                    labels[neighbor] = component
                    pending.append(neighbor)
        sizes.append(size)
    return labels, sizes


def run(values: Sequence[int] | None) -> int:
    decoded = _decode(values)
    if decoded is None:
        return -1
    n, operations = decoded
    adjacency = [set() for _ in range(n)]
    total = 0
    for operation_index, (opcode, first, second) in enumerate(operations, start=1):
        if opcode == 0:
            for vertex in range(first, second - 1):
                adjacency[vertex].add(vertex + 1)
                adjacency[vertex + 1].add(vertex)
            _, sizes = _labels(adjacency)
            observed = len(sizes)
        else:
            labels, sizes = _labels(adjacency)
            if opcode == 1:
                observed = int(labels[first] == labels[second])
            else:
                observed = sizes[labels[first]]
        total += operation_index * observed
    return total


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if type(input_is_null) is not bool or type(input_length) not in (int, type(None)):
        return -1
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1
    if input_length is None:
        input_length = len(values)
    if input_length < 0 or input_length > len(values) or input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    return run(values[:input_length])
