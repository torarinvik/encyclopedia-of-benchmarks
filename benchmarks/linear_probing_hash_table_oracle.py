"""Oracle for the bounded, target-pinned linear-probing hash-table trace."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_INITIAL_CAPACITY = 2
MAX_INITIAL_CAPACITY = 16
MAX_TABLE_CAPACITY = 128
MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8704
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
MAX_KEY = (1 << 31) - 1 - (MAX_TABLE_CAPACITY - 1)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID_RESULT, b""

    initial_capacity, operation_count = values[:2]
    if not MIN_INITIAL_CAPACITY <= initial_capacity <= MAX_INITIAL_CAPACITY:
        return INVALID_RESULT, b""
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""

    table_capacity = initial_capacity
    table = [0] * table_capacity  # Zero is the pinned source's notPresent sentinel.
    tombstone = -1
    size = 0
    records: list[int] = []
    position = 2

    def home(key: int, capacity: int) -> int:
        # The pinned target's std::hash<int> is identity for this positive domain.
        return key % capacity

    def find_slot(key: int) -> int | None:
        index = home(key, table_capacity)
        for _ in range(table_capacity):
            slot = table[index]
            if slot == 0:
                return None
            if slot == key:
                return index
            index = (index + 1) % table_capacity
        return None

    def insertion_slot(key: int) -> int | None:
        index = home(key, table_capacity)
        for _ in range(table_capacity):
            if table[index] in (0, tombstone):
                return index
            index = (index + 1) % table_capacity
        return None

    def rehash() -> None:
        nonlocal table, table_capacity
        old_table = table
        table_capacity *= 2
        table = [0] * table_capacity
        for key in old_table:
            if key in (0, tombstone):
                continue
            index = insertion_slot(key)
            if index is None:
                raise AssertionError("bounded table unexpectedly has no insertion slot")
            table[index] = key

    for _ in range(operation_count):
        if position >= len(values):
            return INVALID_RESULT, b""
        opcode = values[position]
        position += 1
        if opcode in (0, 1, 2, 3):
            if position >= len(values):
                return INVALID_RESULT, b""
            key = values[position]
            position += 1
            if not 1 <= key <= MAX_KEY:
                return INVALID_RESULT, b""

            if opcode == 0:  # Add always takes the next empty/tombstone slot, even for duplicates.
                index = insertion_slot(key)
                if index is None:
                    return INVALID_RESULT, b""
                table[index] = key
                size += 1
                records.extend((0, 1))
                if size * 2 >= table_capacity:
                    rehash()
            elif opcode == 1:  # Missing removal corrupts slot zero in the source; exclude it.
                index = find_slot(key)
                if index is None:
                    return INVALID_RESULT, b""
                table[index] = tombstone
                size -= 1
                records.extend((1, 1))
            elif opcode == 2:
                records.extend((2, int(find_slot(key) is not None)))
            else:  # Generate Hash; positive int hash is identity on the pinned target.
                records.extend((3, key))
        elif opcode == 4:  # Display the slot array, including empty and tombstone markers.
            records.extend((4, table_capacity))
            records.extend(-2 if key == 0 else key for key in table)
        else:
            return INVALID_RESULT, b""

    if position != len(values):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    output = b"".join(struct.pack("<q", word) for word in records)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
