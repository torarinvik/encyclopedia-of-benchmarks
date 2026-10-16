"""Oracle for stable descending-value whole-item greedy selection."""

from __future__ import annotations

MAX_ITEMS = 8
MAX_CAPACITY = 1_000_000
MAX_ITEM_VALUE = 1_000_000
MAX_ITEM_WEIGHT = 1_000_000
MAX_INPUT_LENGTH = 2 + 2 * MAX_ITEMS
VALUE_SHIFT = 36
COUNT_SHIFT = 32


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    capacity, item_count = values[:2]
    if (not 0 <= capacity <= MAX_CAPACITY or not 0 <= item_count <= MAX_ITEMS
            or len(values) != 2 + 2 * item_count):
        return -1
    item_values = values[2:2 + item_count]
    item_weights = values[2 + item_count:]
    if (any(not 0 <= value <= MAX_ITEM_VALUE for value in item_values)
            or any(not 1 <= weight <= MAX_ITEM_WEIGHT for weight in item_weights)):
        return -1

    order = sorted(range(item_count), key=lambda index: -item_values[index])
    selected: list[int] = []
    total_weight = 0
    total_value = 0
    for index in order:
        weight = item_weights[index]
        if total_weight + weight <= capacity:
            selected.append(index + 1)
            total_weight += weight
            total_value += item_values[index]

    packed_order = sum(item_id << (4 * position) for position, item_id in enumerate(selected))
    return (total_value << VALUE_SHIFT) | (len(selected) << COUNT_SHIFT) | packed_order
