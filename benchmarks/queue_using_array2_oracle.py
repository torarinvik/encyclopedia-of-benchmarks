"""Independent list-model oracle for the compacting fixed-array queue."""

from __future__ import annotations

MAX_OPERATIONS = 256
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
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
        opcode, value = packed[1 + 2 * i:3 + 2 * i]
        if opcode == 1:
            if not -VALUE_LIMIT <= value <= VALUE_LIMIT:
                return -1
        elif opcode in (2, 3):
            if value != 0:
                return -1
        else:
            return -1
        operations.append((opcode, value))

    queue: list[int] = []
    digest = 0
    for opcode, value in operations:
        if opcode == 1:
            if len(queue) < 10:
                queue.append(value)
        elif opcode == 2 and queue:
            queue.pop(0)

        tokens = (opcode, len(queue), *(item + VALUE_OFFSET for item in queue))
        for token in tokens:
            digest = (digest * HASH_MULTIPLIER + token) % HASH_MODULUS
    return digest
