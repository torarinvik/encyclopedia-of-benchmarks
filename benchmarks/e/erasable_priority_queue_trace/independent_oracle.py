"""Sorted-multiset reference for the erasable minimum-priority queue trace."""

from __future__ import annotations

from collections.abc import Sequence
from bisect import bisect_left, insort

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return -1
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 128:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return -1

    count = values[0]
    if not 0 <= count <= 63 or len(values) != 1 + 2 * count:
        return -1
    queue: list[int] = []
    checksum = 0
    for index, offset in enumerate(range(1, len(values), 2), start=1):
        opcode, value = values[offset], values[offset + 1]
        response = 0
        if opcode == 0:
            if not -100 <= value <= 100:
                return -1
            insort(queue, value)
        elif opcode == 1:
            if not -100 <= value <= 100:
                return -1
            position = bisect_left(queue, value)
            if position == len(queue) or queue[position] != value:
                return -1
            queue.pop(position)
            response = 1
        elif opcode == 2:
            if value != 0:
                return -1
            response = queue[0] if queue else -101
        elif opcode == 3:
            if value != 0 or not queue:
                return -1
            response = queue.pop(0)
        else:
            return -1
        checksum += index * (opcode * 202 + response + 101)
    return checksum
