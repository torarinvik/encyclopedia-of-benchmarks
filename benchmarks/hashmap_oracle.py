"""Dictionary-model oracle for the bounded Go hashmap operation stream."""

from __future__ import annotations

import struct

MAX_OPERATIONS = 128
MAX_ENTRIES = 128
MAX_INITIAL_CAPACITY = 64
MAX_CAPACITY = 256
MAX_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * (3 + 3 * MAX_OPERATIONS)
MIN_KEY = -(1 << 31)
MAX_KEY = (1 << 31) - 1
MIN_VALUE = -(1 << 31)
MAX_VALUE = (1 << 31) - 1
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
FNV_OFFSET_BASIS = 14_695_981_039_346_656_037
FNV_PRIME = 1_099_511_628_211
MASK_64 = (1 << 64) - 1


def key_hash(key: int) -> int:
    """Return the pinned source's folded FNV-1a hash of fmt's decimal key."""
    digest = FNV_OFFSET_BASIS
    for byte in str(key).encode("ascii"):
        digest = ((digest ^ byte) * FNV_PRIME) & MASK_64
    return digest ^ (digest >> 16)


def bucket_index(key: int, capacity: int) -> int:
    return key_hash(key) & (capacity - 1)


def _valid(values: list[int] | tuple[int, ...]) -> bool:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return False
    capacity, operation_count = values[0], values[1]
    if (capacity < 1 or capacity > MAX_INITIAL_CAPACITY
            or capacity & (capacity - 1) != 0
            or operation_count < 0 or operation_count > MAX_OPERATIONS
            or len(values) != 2 + 3 * operation_count):
        return False
    for offset in range(2, len(values), 3):
        operation, key, value = values[offset:offset + 3]
        if operation not in (0, 1, 2) or not MIN_KEY <= key <= MAX_KEY:
            return False
        if operation == 0:
            if not MIN_VALUE <= value <= MAX_VALUE:
                return False
        elif value != 0:
            return False
    return True


def expected_output(
    values: list[int] | tuple[int, ...],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Model operations with a dictionary and serialize exact observable results.

    The output is little-endian signed i64 values:
    ``[query_count, (opcode, present[, value])* , final_size, final_capacity]``.
    """
    if not _valid(values):
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""

    initial_capacity, operation_count = values[0], values[1]
    map_capacity = initial_capacity
    entries: dict[int, int] = {}
    queries: list[tuple[int, int, int | None]] = []

    for index in range(operation_count):
        operation, key, value = values[2 + 3 * index:5 + 3 * index]
        if operation == 0:
            is_new = key not in entries
            entries[key] = value
            if is_new and len(entries) * 4 > map_capacity * 3:
                map_capacity *= 2
        elif operation == 1:
            if key in entries:
                queries.append((operation, 1, entries[key]))
            else:
                queries.append((operation, 0, None))
        else:
            queries.append((operation, int(key in entries), None))

    output_values = [len(queries)]
    for operation, present, value in queries:
        output_values.extend((operation, present))
        if operation == 1:
            output_values.append(0 if value is None else value)
    output_values.extend((len(entries), map_capacity))
    output = b"".join(struct.pack("<q", value) for value in output_values)

    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
