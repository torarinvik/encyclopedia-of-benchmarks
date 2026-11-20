"""Recursive displacement reference for bounded LCFS hashing."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT, MAX_CAPACITY, MAX_KEY, MAX_N, MAX_PARSEABLE_INPUT_LENGTH,
)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    capacity, count = values[:2]
    if (not 1 <= capacity <= MAX_CAPACITY or not 0 <= count <= min(MAX_N, capacity)
            or len(values) != count + 2):
        return INVALID_RESULT
    keys = values[2:]
    if any(not 0 <= key <= MAX_KEY for key in keys) or len(set(keys)) != count:
        return INVALID_RESULT

    table: list[int | None] = [None] * capacity

    def displace(slot: int, incoming: int, remaining: int) -> int:
        resident = table[slot]
        if resident is None:
            table[slot] = incoming
            return 0
        if remaining == 0:
            return INVALID_RESULT
        table[slot] = incoming
        rest = displace((slot + 1) % capacity, resident, remaining - 1)
        return INVALID_RESULT if rest == INVALID_RESULT else rest + 1

    total = 0
    for key in keys:
        moved = displace(key % capacity, key, capacity)
        if moved == INVALID_RESULT:
            return INVALID_RESULT
        total += moved
    return total
