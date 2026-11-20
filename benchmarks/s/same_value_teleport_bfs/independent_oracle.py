"""Independent pairwise-edge BFS reference for same-value teleports."""
from __future__ import annotations

from .primary_oracle import (
    I64_MIN,
    I64_MAX,
    INVALID_RESULT,
    MAX_ARRAY_LENGTH,
    MAX_INPUT_LENGTH,
    MIN_VALUE,
    MAX_VALUE,
)


def expected_result(values):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    count = values[0]
    if type(count) is not int or not 1 <= count <= MAX_ARRAY_LENGTH or len(values) != count + 1:
        return INVALID_RESULT
    items = values[1:]
    if any(value < MIN_VALUE or value > MAX_VALUE for value in items):
        return INVALID_RESULT

    distance = [-1] * count
    distance[0] = 0
    queue = [0]
    while queue:
        index = queue.pop(0)
        if index == count - 1:
            return distance[index]
        for neighbor in range(count):
            if neighbor == index or distance[neighbor] >= 0:
                continue
            if abs(neighbor - index) == 1 or items[neighbor] == items[index]:
                distance[neighbor] = distance[index] + 1
                queue.append(neighbor)
    return distance[-1]
