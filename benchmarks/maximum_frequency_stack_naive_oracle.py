"""Independent active-list rescan oracle for maximum-frequency stack traces."""
from __future__ import annotations

import struct
from typing import Sequence

MAX_OPERATIONS = 64
MIN_VALUE = -8
MAX_VALUE = 8
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 256
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[tuple[int, int]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    size = len(values)
    if size < 1 or size > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != size
        or input_length < 0 or input_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    for value in values:
        if type(value) is not int or value < -(1 << 63) or value >= (1 << 63):
            return None
    count = values[0]
    if count < 0 or count > MAX_OPERATIONS or size != 1 + 2 * count:
        return None
    decoded: list[tuple[int, int]] = []
    for position in range(count):
        opcode = values[1 + 2 * position]
        argument = values[2 + 2 * position]
        if opcode == 0:
            if argument < MIN_VALUE or argument > MAX_VALUE:
                return None
        elif opcode == 1:
            if argument != 0:
                return None
        else:
            return None
        decoded.append((opcode, argument))
    return decoded


def _rescan_run(operations: list[tuple[int, int]]) -> bytes | None:
    active: list[int] = []
    popped: list[int] = []
    for opcode, value in operations:
        if opcode == 0:
            active.append(value)
            continue
        if not active:
            return None
        counts: dict[int, int] = {}
        for current in active:
            counts[current] = counts.get(current, 0) + 1
        highest = max(counts.values())
        selected_position = -1
        selected_value = 0
        for position in range(len(active) - 1, -1, -1):
            candidate = active[position]
            if counts[candidate] == highest:
                selected_position = position
                selected_value = candidate
                break
        active.pop(selected_position)
        popped.append(selected_value)
    return b"".join(struct.pack("<q", value) for value in popped)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    operations = _decode(values, input_length, input_is_null)
    if operations is None:
        return INVALID_RESULT, b""
    payload = _rescan_run(operations)
    if payload is None:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if len(payload) and (
        output_is_null
        or output_capacity is not None and output_capacity < len(payload)
    ):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(payload), payload
