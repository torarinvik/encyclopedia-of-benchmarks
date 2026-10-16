"""Independent set-model oracle for the two-replica TwoPSet benchmark."""

from __future__ import annotations

MAX_OPERATIONS = 256
MAX_INPUT_LENGTH = 1 + 4 * MAX_OPERATIONS
ELEMENT_LIMIT = 63
HASH_MULTIPLIER = 1_000_003
HASH_MODULUS = 1_000_000_007


def oracle(packed: list[int]) -> int:
    if not isinstance(packed, list) or any(type(value) is not int for value in packed):
        return -1
    if not packed or len(packed) > MAX_INPUT_LENGTH:
        return -1
    operation_count = packed[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(packed) != 1 + 4 * operation_count:
        return -1

    operations: list[tuple[int, int, int, int]] = []
    for i in range(operation_count):
        opcode, set_id, value, other_id = packed[1 + 4 * i:5 + 4 * i]
        if opcode in (0, 1, 2):
            if set_id not in (0, 1) or not 0 <= value <= ELEMENT_LIMIT or other_id != 0:
                return -1
        elif opcode in (3, 4):
            if set_id not in (0, 1) or other_id not in (0, 1) or value != 0:
                return -1
        else:
            return -1
        operations.append((opcode, set_id, value, other_id))

    additions = [set(), set()]
    tombstones = [set(), set()]
    digest = 0
    for opcode, set_id, value, other_id in operations:
        result = 0
        if opcode == 0:
            additions[set_id].add(value)
        elif opcode == 1:
            if value in additions[set_id] and value not in tombstones[set_id]:
                tombstones[set_id].add(value)
        elif opcode == 2:
            result = int(value in additions[set_id] and value not in tombstones[set_id])
        elif opcode == 3:
            result = int(additions[set_id].issubset(additions[other_id])
                         and tombstones[set_id].issubset(tombstones[other_id]))
        else:
            additions[set_id] = additions[set_id] | additions[other_id]
            tombstones[set_id] = tombstones[set_id] | tombstones[other_id]

        digest = (digest * HASH_MULTIPLIER + opcode) % HASH_MODULUS
        digest = (digest * HASH_MULTIPLIER + result) % HASH_MODULUS

    for set_id in range(2):
        for members in (additions[set_id], tombstones[set_id]):
            for value in range(ELEMENT_LIMIT + 1):
                digest = (digest * HASH_MULTIPLIER + int(value in members)) % HASH_MODULUS
    return digest
