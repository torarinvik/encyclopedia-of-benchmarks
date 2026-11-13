"""Direct FIFO-list oracle for minimum-queue operation traces."""

from __future__ import annotations

MAX_OPERATIONS = 32
QUEUE_CAPACITY = 16
VALUE_MIN = -1000
VALUE_MAX = 1000
CHECKSUM_OFFSET = 1001
MAX_VALID_INPUT_LENGTH = 57
MAX_PARSEABLE_INPUT_LENGTH = 65


def expected_result(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1
    if len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return -1
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1
    count = values[0]
    if count < 0 or count > MAX_OPERATIONS:
        return -1

    queue: list[int] = []
    checksum = 0
    cursor = 1
    for operation_index in range(count):
        if cursor == len(values):
            return -1
        opcode = values[cursor]
        cursor += 1
        if opcode == 0:
            if cursor == len(values):
                return -1
            value = values[cursor]
            cursor += 1
            if value < VALUE_MIN or value > VALUE_MAX or len(queue) == QUEUE_CAPACITY:
                return -1
            queue.append(value)
        elif opcode == 1:
            if not queue:
                return -1
            observed = queue.pop(0)
            checksum += (operation_index + 1) * (observed + CHECKSUM_OFFSET)
        elif opcode == 2:
            if not queue:
                return -1
            observed = min(queue)
            checksum += (operation_index + 1) * (observed + CHECKSUM_OFFSET)
        else:
            return -1
    if cursor != len(values):
        return -1
    for position, value in enumerate(queue, 1):
        checksum += position * (value + CHECKSUM_OFFSET)
    return checksum
