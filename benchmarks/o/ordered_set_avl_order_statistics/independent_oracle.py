"""Sorted-list oracle for the bounded dynamic ordered-set profile."""

from __future__ import annotations

from bisect import bisect_left, bisect_right
from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    INVALID_RESULT,
    MAX_ITEMS,
    MAX_KEY,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[list[int], list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    size = len(values)
    if input_length is None:
        input_length = size
    if (
        type(input_length) is not int
        or input_length != size
        or size < 2
        or size > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    initial_count, operation_count = values[0], values[1]
    if not 0 <= initial_count <= MAX_ITEMS or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if size != 2 + initial_count + 2 * operation_count:
        return None
    initial = list(values[2 : 2 + initial_count])
    if any(not 0 <= key <= MAX_KEY for key in initial):
        return None
    if any(initial[i - 1] >= initial[i] for i in range(1, len(initial))):
        return None
    start = 2 + initial_count
    operations: list[tuple[int, int]] = []
    for i in range(operation_count):
        opcode, key = values[start + 2 * i : start + 2 * i + 2]
        if opcode not in (0, 1, 2, 3, 4, 5) or not 0 <= key <= MAX_KEY:
            return None
        if opcode == 2 and key < 1:
            return None
        operations.append((opcode, key))
    return initial, operations


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Simulate the specified operations with a sorted Python list."""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    items, operations = decoded
    items = list(items)
    checksum = 0
    query_index = 0
    for opcode, key in operations:
        position = bisect_left(items, key)
        if opcode == 0:
            if position == len(items) or items[position] != key:
                items.insert(position, key)
        elif opcode == 1:
            if position < len(items) and items[position] == key:
                items.pop(position)
        else:
            if opcode == 2:
                answer = items[key - 1] if key <= len(items) else -1
            elif opcode == 3:
                answer = bisect_right(items, key)
            elif opcode == 4:
                predecessor_index = bisect_right(items, key) - 1
                answer = items[predecessor_index] if predecessor_index >= 0 else -1
            else:
                answer = items[position] if position < len(items) else -1
            query_index += 1
            checksum += query_index * (answer + 1)
    return checksum
