"""Explicit adjacency graph and BFS component-membership reference."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_ITEMS,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    item_count, operation_count = values[:2]
    if not 1 <= item_count <= MAX_ITEMS or not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if len(values) != 2 + 3 * operation_count or len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT

    graph: list[list[int]] = [[] for _ in range(item_count)]
    checksum = 0
    cursor = 2
    for ordinal in range(1, operation_count + 1):
        opcode, first, second = values[cursor:cursor + 3]
        cursor += 3
        if opcode == 0:
            if not (0 <= first < item_count and 0 <= second < item_count):
                return INVALID_RESULT
            reached = {first}
            queue = deque([first])
            while queue:
                node = queue.popleft()
                for neighbor in graph[node]:
                    if neighbor not in reached:
                        reached.add(neighbor)
                        queue.append(neighbor)
            merged = int(second not in reached)
            if merged:
                graph[first].append(second)
                graph[second].append(first)
            observed = merged
        elif opcode == 1:
            if not 0 <= first < item_count or second != 0:
                return INVALID_RESULT
            reached = {first}
            queue = deque([first])
            while queue:
                node = queue.popleft()
                for neighbor in graph[node]:
                    if neighbor not in reached:
                        reached.add(neighbor)
                        queue.append(neighbor)
            observed = sum(1 << node for node in reached)
        else:
            return INVALID_RESULT
        checksum += ordinal * (observed + 1)
    return checksum
