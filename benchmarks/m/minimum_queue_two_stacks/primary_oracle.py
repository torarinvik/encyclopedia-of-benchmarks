"""Minimum queue oracle using two stacks augmented with prefix minima."""

from __future__ import annotations

MAX_OPERATIONS = 32
QUEUE_CAPACITY = 16
VALUE_MIN = -1000
VALUE_MAX = 1000
CHECKSUM_OFFSET = 1001
MAX_VALID_INPUT_LENGTH = 57
MAX_PARSEABLE_INPUT_LENGTH = 65


def expected_result(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1
    if (len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return -1

    input_values: list[int] = []
    input_minimums: list[int] = []
    output_values: list[int] = []
    output_minimums: list[int] = []
    checksum = 0
    cursor = 1

    for operation_index in range(operation_count):
        if cursor >= len(values):
            return -1
        opcode = values[cursor]
        cursor += 1
        if opcode == 0:
            if cursor >= len(values):
                return -1
            value = values[cursor]
            cursor += 1
            if not VALUE_MIN <= value <= VALUE_MAX:
                return -1
            if len(input_values) + len(output_values) >= QUEUE_CAPACITY:
                return -1
            input_values.append(value)
            input_minimums.append(
                value if len(input_minimums) == 0 else min(value, input_minimums[-1])
            )
        elif opcode == 1:
            if not input_values and not output_values:
                return -1
            if not output_values:
                while input_values:
                    moved = input_values.pop()
                    input_minimums.pop()
                    output_values.append(moved)
                    output_minimums.append(
                        moved if len(output_minimums) == 0 else min(moved, output_minimums[-1])
                    )
            observed = output_values.pop()
            output_minimums.pop()
            checksum += (operation_index + 1) * (observed + CHECKSUM_OFFSET)
        elif opcode == 2:
            if not input_values and not output_values:
                return -1
            if not input_values:
                observed = output_minimums[-1]
            elif not output_values:
                observed = input_minimums[-1]
            else:
                observed = min(input_minimums[-1], output_minimums[-1])
            checksum += (operation_index + 1) * (observed + CHECKSUM_OFFSET)
        else:
            return -1

    if cursor != len(values):
        return -1

    position = 0
    for value in reversed(output_values):
        position += 1
        checksum += position * (value + CHECKSUM_OFFSET)
    for value in input_values:
        position += 1
        checksum += position * (value + CHECKSUM_OFFSET)
    return checksum
