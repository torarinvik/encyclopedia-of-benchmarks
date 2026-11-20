"""Bitmap-based reference for a bounded, fixed-capacity hopscotch table."""

from __future__ import annotations

from collections.abc import Sequence

TABLE_SIZE = 16
NEIGHBORHOOD = 4
MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 32 + MAX_OPERATIONS
WORKSPACE_BYTES = 1024


def _parse(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 3 * count:
        return None
    operations: list[tuple[int, int, int]] = []
    home_by_key: dict[int, int] = {}
    for index in range(count):
        opcode, key, home = values[1 + 3 * index:4 + 3 * index]
        if opcode not in (1, 2) or not 0 <= key < 64 or not 0 <= home < TABLE_SIZE:
            return None
        previous_home = home_by_key.setdefault(key, home)
        if previous_home != home:
            return None
        operations.append((opcode, key, home))
    return operations


def _run_bitmap(operations: list[tuple[int, int, int]]) -> bytes:
    keys = [-1] * TABLE_SIZE
    homes = [0] * TABLE_SIZE
    hop = [0] * TABLE_SIZE
    statuses = bytearray()

    def distance(start: int, end: int) -> int:
        return (end - start) % TABLE_SIZE

    def find(key: int, home: int) -> bool:
        bits = hop[home]
        for offset in range(NEIGHBORHOOD):
            if bits & (1 << offset):
                slot = (home + offset) % TABLE_SIZE
                if keys[slot] == key:
                    return True
        return False

    def insert(key: int, home: int) -> int:
        if find(key, home):
            return 2
        free = -1
        for offset in range(TABLE_SIZE):
            slot = (home + offset) % TABLE_SIZE
            if keys[slot] < 0:
                free = slot
                break
        if free < 0:
            return 0
        offset_from_home = distance(home, free)
        while offset_from_home >= NEIGHBORHOOD:
            moved = False
            # Start at free-(H-1), as in Figure 1, then scan toward free.
            for back in range(NEIGHBORHOOD - 1, 0, -1):
                candidate_home = (free - back) % TABLE_SIZE
                candidate_distance = distance(candidate_home, free)
                if distance(home, candidate_home) >= offset_from_home:
                    continue
                for old_offset in range(candidate_distance):
                    if not (hop[candidate_home] & (1 << old_offset)):
                        continue
                    old_slot = (candidate_home + old_offset) % TABLE_SIZE
                    if keys[old_slot] < 0 or homes[old_slot] != candidate_home:
                        continue
                    if distance(home, old_slot) >= offset_from_home:
                        continue
                    keys[free] = keys[old_slot]
                    homes[free] = homes[old_slot]
                    keys[old_slot] = -1
                    homes[old_slot] = 0
                    hop[candidate_home] &= ~(1 << old_offset)
                    hop[candidate_home] |= 1 << candidate_distance
                    free = old_slot
                    offset_from_home = distance(home, free)
                    moved = True
                    break
                if moved:
                    break
            if not moved:
                # Existing legal relocations stay in place; the new key is not added.
                return 0
        keys[free] = key
        homes[free] = home
        hop[home] |= 1 << offset_from_home
        return 1

    for opcode, key, home in operations:
        if opcode == 1:
            statuses.append(insert(key, home))
        else:
            statuses.append(1 if find(key, home) else 0)

    slot_codes = bytes(0 if key < 0 else key + 1 for key in keys)
    return bytes(statuses) + slot_codes + bytes(hop)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    operations = _parse(values)
    if operations is None:
        return -1, b""
    result = _run_bitmap(operations)
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
