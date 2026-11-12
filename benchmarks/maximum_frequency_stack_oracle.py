"""Frequency-bucket oracle for a bounded maximum-frequency stack trace."""
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


def _read_operations(values: Sequence[int] | None, input_length: int | None,
                     input_is_null: bool) -> list[tuple[int, int]] | None:
    if (input_is_null or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 2 * operation_count:
        return None
    operations: list[tuple[int, int]] = []
    for index in range(operation_count):
        opcode, value = values[1 + 2 * index:3 + 2 * index]
        if opcode == 0:
            if not MIN_VALUE <= value <= MAX_VALUE:
                return None
        elif opcode == 1:
            if value != 0:
                return None
        else:
            return None
        operations.append((opcode, value))
    return operations


def _frequency_bucket_run(operations: list[tuple[int, int]]) -> bytes | None:
    frequency = [0] * (MAX_VALUE - MIN_VALUE + 1)
    groups: list[list[int]] = [[] for _ in range(MAX_OPERATIONS + 1)]
    maximum_frequency = 0
    popped: list[int] = []
    for opcode, value in operations:
        if opcode == 0:
            value_index = value - MIN_VALUE
            frequency[value_index] += 1
            new_frequency = frequency[value_index]
            groups[new_frequency].append(value)
            if new_frequency > maximum_frequency:
                maximum_frequency = new_frequency
        else:
            if maximum_frequency == 0 or not groups[maximum_frequency]:
                return None
            value_to_pop = groups[maximum_frequency].pop()
            popped.append(value_to_pop)
            frequency[value_to_pop - MIN_VALUE] -= 1
            if not groups[maximum_frequency]:
                maximum_frequency -= 1
    return b"".join(struct.pack("<q", value) for value in popped)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    operations = _read_operations(values, input_length, input_is_null)
    if operations is None:
        return INVALID_RESULT, b""
    payload = _frequency_bucket_run(operations)
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
