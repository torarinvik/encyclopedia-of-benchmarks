"""Independent logical-list oracle for the fixed-capacity ring buffer."""

from __future__ import annotations

MAX_OPERATIONS = 256
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
CAPACITY = 8
VALUE_LIMIT = 1_000_000
VALUE_OFFSET = 1_000_001
HASH_MULTIPLIER = 1_000_003
HASH_MODULUS = 1_000_000_007


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
        opcode, payload = packed[1 + 2 * i:3 + 2 * i]
        if opcode == 0:
            if not -VALUE_LIMIT <= payload <= VALUE_LIMIT:
                return -1
        elif opcode == 4:
            if not 0 <= payload <= VALUE_LIMIT:
                return -1
        elif opcode in (1, 2, 3, 5, 6, 7, 8, 9):
            if payload != 0:
                return -1
        else:
            return -1
        operations.append((opcode, payload))

    queue: list[int] = []
    digest = 0
    for opcode, payload in operations:
        status = 0
        result = 0
        if opcode == 0:
            if len(queue) == CAPACITY:
                status = 1
            else:
                queue.append(payload)
        elif opcode == 1:
            if queue:
                result = queue.pop(0)
            else:
                status = 2
        elif opcode == 2:
            if queue:
                result = queue[0]
            else:
                status = 2
        elif opcode == 3:
            if queue:
                result = queue[-1]
            else:
                status = 2
        elif opcode == 4:
            if payload < len(queue):
                result = queue[payload]
            else:
                status = 3
        elif opcode == 5:
            queue.clear()
        elif opcode == 6:
            result = len(queue)
        elif opcode == 7:
            result = CAPACITY - len(queue)
        elif opcode == 8:
            result = int(len(queue) == 0)
        elif opcode == 9:
            result = int(len(queue) == CAPACITY)

        tokens = (opcode, status, result + VALUE_OFFSET, len(queue),
                  *(item + VALUE_OFFSET for item in queue))
        for token in tokens:
            digest = (digest * HASH_MULTIPLIER + token) % HASH_MODULUS
    return digest
