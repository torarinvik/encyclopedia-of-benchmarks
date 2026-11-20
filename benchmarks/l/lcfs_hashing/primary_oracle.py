"""Bounded LCFS linear-probing insertion and resident-displacement count."""

from __future__ import annotations

from collections.abc import Sequence

MAX_CAPACITY = 32
MAX_N = MAX_CAPACITY
MAX_KEY = 1_000_000
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_WORKSPACE_BYTES = 8 * MAX_CAPACITY
MAX_DISPLACEMENTS = MAX_N * (MAX_N - 1) // 2
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    capacity, count = values[:2]
    if (not 1 <= capacity <= MAX_CAPACITY or not 0 <= count <= capacity
            or len(values) != count + 2):
        return None
    keys = values[2:]
    if (any(not 0 <= key <= MAX_KEY for key in keys)
            or len(set(keys)) != count):
        return None
    return capacity, keys


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    capacity, keys = parsed
    table = [-1] * capacity
    displacements = 0
    for key in keys:
        slot = key % capacity
        incoming = key
        probes = 0
        while table[slot] != -1:
            if probes >= capacity:
                return INVALID_RESULT
            resident = table[slot]
            table[slot] = incoming
            incoming = resident
            slot = (slot + 1) % capacity
            probes += 1
            displacements += 1
        table[slot] = incoming
    return displacements
