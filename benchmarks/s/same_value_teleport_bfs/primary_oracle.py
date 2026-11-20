"""Grouped-value BFS reference for the bounded same-value teleport profile."""
from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -2
MAX_ARRAY_LENGTH = 64
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 1
MIN_VALUE = -64
MAX_VALUE = 64


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
    if count == 1:
        return 0

    groups: list[list[int]] = [[] for _ in range(MAX_VALUE - MIN_VALUE + 1)]
    for index, value in enumerate(items):
        groups[value - MIN_VALUE].append(index)

    distance = [-1] * count
    queue = [0] * count
    front = 0
    back = 1
    queue[0] = 0
    distance[0] = 0
    while front < back:
        index = queue[front]
        front += 1
        if index == count - 1:
            return distance[index]

        neighbors = (index - 1, index + 1)
        for neighbor in neighbors:
            if 0 <= neighbor < count and distance[neighbor] < 0:
                distance[neighbor] = distance[index] + 1
                queue[back] = neighbor
                back += 1

        bucket = items[index] - MIN_VALUE
        same = groups[bucket]
        if same:
            for neighbor in same:
                if distance[neighbor] < 0:
                    distance[neighbor] = distance[index] + 1
                    queue[back] = neighbor
                    back += 1
            groups[bucket] = []

    return distance[-1]
