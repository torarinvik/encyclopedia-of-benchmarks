"""Independent list-model oracle for the fixed-array linear queue workload."""

from __future__ import annotations

MAX_OPERATIONS = 512
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS


def oracle(packed: list[int]) -> int:
    if not isinstance(packed, list) or any(type(value) is not int for value in packed):
        return -1
    if not packed or len(packed) > MAX_INPUT_LENGTH:
        return -1
    operation_count = packed[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(packed) != 1 + 2 * operation_count:
        return -1

    operations: list[tuple[int, int]] = []
    for i in range(operation_count):
        opcode, value = packed[1 + 2 * i:3 + 2 * i]
        if opcode == 0:
            if not -128 <= value <= 127:
                return -1
        elif opcode == 1:
            if value != 0:
                return -1
        else:
            return -1
        operations.append((opcode, value))

    values = [0] * 10
    front = rear = -1
    checksum = 0
    dequeue_ordinal = 0
    for opcode, value in operations:
        if opcode == 0:
            if rear == 9:
                continue
            if front == -1 and rear == -1:
                front = rear = 0
                values[rear] = value
            elif rear < 10:
                rear += 1
                values[rear] = value
        else:
            if front == -1:
                dequeued = 0
            elif front == rear:
                dequeued = values[front]
                front = rear = -1
            else:
                dequeued = values[front]
                front += 1
            dequeue_ordinal += 1
            checksum += dequeue_ordinal * (dequeued + 128)
    return checksum
