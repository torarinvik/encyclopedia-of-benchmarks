"""Flat Python-list oracle for indexed block-list semantics."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INITIAL_ITEMS = 16
MAX_OPERATIONS = 64
MAX_INSERTS = 32
MAX_ACCESSES = 32
MAX_INPUT_LENGTH = 178
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = 179
MAX_OUTPUT_BYTES = 256
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], list[tuple[int, ...]], int] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    initial_count = values[0]
    if not 0 <= initial_count <= MAX_INITIAL_ITEMS or len(values) < initial_count + 2:
        return None
    initial = list(values[1:1 + initial_count])
    if any(not -1_000_000 <= value <= 1_000_000 for value in initial):
        return None
    count = values[initial_count + 1]
    if not 0 <= count <= MAX_OPERATIONS:
        return None
    cursor = initial_count + 2
    size = initial_count
    inserts = accesses = 0
    operations: list[tuple[int, ...]] = []
    for _ in range(count):
        if cursor >= len(values):
            return None
        opcode = values[cursor]
        if opcode == 0:
            if cursor + 3 > len(values):
                return None
            index, value = values[cursor + 1:cursor + 3]
            if not 0 <= index <= size or not -1_000_000 <= value <= 1_000_000:
                return None
            inserts += 1
            if inserts > MAX_INSERTS:
                return None
            operations.append((0, index, value))
            size += 1
            cursor += 3
        elif opcode == 1:
            if cursor + 2 > len(values):
                return None
            index = values[cursor + 1]
            if not 0 <= index < size:
                return None
            accesses += 1
            if accesses > MAX_ACCESSES:
                return None
            operations.append((1, index))
            cursor += 2
        else:
            return None
    if cursor != len(values) or size > MAX_INITIAL_ITEMS + MAX_INSERTS:
        return None
    return initial, operations, accesses


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    sequence, operations, access_count = parsed
    if access_count == 0:
        return 0, b""
    if type(output_is_null) is not bool:
        return CAPACITY_ERROR, b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    required = 8 * access_count
    if (type(effective_capacity) is not int or effective_capacity < required
            or output_is_null):
        return CAPACITY_ERROR, b""
    answers: list[int] = []
    for operation in operations:
        if operation[0] == 0:
            sequence.insert(operation[1], operation[2])
        else:
            answers.append(sequence[operation[1]])
    payload = b"".join(struct.pack("<q", value) for value in answers)
    return len(payload), payload


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]
