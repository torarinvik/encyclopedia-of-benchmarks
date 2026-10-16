"""Exact recorder oracle for the bounded branch-and-bound knapsack contract."""

from __future__ import annotations

from fractions import Fraction

MAX_ITEMS = 8
MAX_CAPACITY = 8000
MAX_ITEM_WEIGHT = 1000
MAX_ITEM_VALUE = 1000
MAX_INPUT_LENGTH = 2 + 2 * MAX_ITEMS
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    count, capacity = values[:2]
    if (not 0 <= count <= MAX_ITEMS or not 0 <= capacity <= MAX_CAPACITY
            or len(values) != 2 + 2 * count):
        return -1, b""
    items = []
    for index in range(count):
        weight, value = values[2 + 2 * index:4 + 2 * index]
        if not 1 <= weight <= MAX_ITEM_WEIGHT or not 1 <= value <= MAX_ITEM_VALUE:
            return -1, b""
        items.append((index, weight, value))

    ordered = sorted(items, key=lambda item: Fraction(item[2], item[1]), reverse=True)
    queue = [(-1, 0, 0, 0)]
    head = 0
    best_value = 0
    best_mask = 0

    def fractional_bound(level: int, weight: int, value: int) -> Fraction:
        room = capacity - weight
        bound = Fraction(value)
        index = level + 1
        while room > 0 and index < count:
            _, item_weight, item_value = ordered[index]
            if item_weight <= room:
                bound += item_value
                room -= item_weight
            else:
                bound += Fraction(item_value * room, item_weight)
                room = 0
            index += 1
        return bound

    while head < len(queue):
        level, weight, value, mask = queue[head]
        head += 1
        if level == count - 1:
            continue
        next_level = level + 1
        _, item_weight, item_value = ordered[next_level]
        left_weight, left_value = weight + item_weight, value + item_value
        left_mask = mask | (1 << next_level)
        if left_weight <= capacity and left_value > best_value:
            best_value, best_mask = left_value, left_mask
        if fractional_bound(next_level, left_weight, left_value) > best_value and left_weight < capacity:
            queue.append((next_level, left_weight, left_value, left_mask))
        if fractional_bound(next_level, weight, value) > best_value:
            queue.append((next_level, weight, value, mask))

    chosen = bytes(ordered[level][0] for level in range(count - 1, -1, -1)
                   if best_mask & (1 << level))
    return len(chosen), chosen
