"""Oracle for the bounded Java LIFOCache operation-stream benchmark."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_CAPACITY = 16
MAX_OPERATIONS = 64
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16 * MAX_OPERATIONS
INVALID_RESULT = -1
OUTPUT_ERROR = -2

PUT = 0
GET = 1
REMOVE = 2
SIZE = 3
HITS = 4
MISSES = 5
CLEAR = 6


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return two result integers per operation in little-endian order."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if (len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    cache_capacity, operation_count = values[0], values[1]
    if not 1 <= cache_capacity <= MAX_CAPACITY or not 1 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""
    if len(values) != 2 + 3 * operation_count:
        return INVALID_RESULT, b""

    operations: list[tuple[int, int, int]] = []
    offset = 2
    for _ in range(operation_count):
        opcode, key, value = values[offset:offset + 3]
        offset += 3
        if not PUT <= opcode <= CLEAR:
            return INVALID_RESULT, b""
        if opcode in (PUT, GET, REMOVE):
            if not MIN_I32 <= key <= MAX_I32:
                return INVALID_RESULT, b""
            if opcode == PUT:
                if not MIN_I32 <= value <= MAX_I32:
                    return INVALID_RESULT, b""
            elif value != 0:
                return INVALID_RESULT, b""
        elif key != 0 or value != 0:
            return INVALID_RESULT, b""
        operations.append((opcode, key, value))
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    keys: list[int] = []  # oldest at index 0; youngest at the tail
    entries: dict[int, int] = {}
    hits = 0
    misses = 0
    results: list[int] = []
    for opcode, key, value in operations:
        if opcode == PUT:
            if key in entries:
                keys.remove(key)
                del entries[key]
            if len(entries) >= cache_capacity:
                youngest = keys.pop()
                del entries[youngest]
            keys.append(key)
            entries[key] = value
            results.extend((1, 0))
        elif opcode == GET:
            if key in entries:
                hits += 1
                results.extend((1, entries[key]))
            else:
                misses += 1
                results.extend((0, 0))
        elif opcode == REMOVE:
            if key in entries:
                removed = entries.pop(key)
                keys.remove(key)
                results.extend((1, removed))
            else:
                results.extend((0, 0))
        elif opcode == SIZE:
            results.extend((len(entries), 0))
        elif opcode == HITS:
            results.extend((hits, 0))
        elif opcode == MISSES:
            results.extend((misses, 0))
        else:  # CLEAR
            keys.clear()
            entries.clear()
            hits = 0
            misses = 0
            results.extend((1, 0))

    output = b"".join(struct.pack("<q", result) for result in results)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(results), output
