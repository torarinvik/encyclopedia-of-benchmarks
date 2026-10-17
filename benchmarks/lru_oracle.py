"""Oracle for the bounded operation-trace port of TheAlgorithms/Go LRU cache."""

from __future__ import annotations

import struct
from collections.abc import Sequence


MIN_CAPACITY = 2
MAX_CAPACITY = 16
MAX_OPERATION_COUNT = 32
MIN_KEY = -1_000_000
MAX_KEY = 1_000_000
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_OPERATION_COUNT
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_FIELDS = 114
MAX_OUTPUT_BYTES = MAX_OUTPUT_FIELDS * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Validate and run a bounded trace, returning its little-endian records."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX
           for value in values):
        return INVALID_RESULT, b""

    capacity, operation_count = values[:2]
    if not MIN_CAPACITY <= capacity <= MAX_CAPACITY:
        return INVALID_RESULT, b""
    if not 0 <= operation_count <= MAX_OPERATION_COUNT:
        return INVALID_RESULT, b""
    if len(values) != 2 + 3 * operation_count:
        return INVALID_RESULT, b""

    cache: dict[int, int] = {}
    lru_to_mru: list[int] = []
    seen_put_keys: set[int] = set()
    records: list[int] = []
    cursor = 2

    for _ in range(operation_count):
        opcode, key, value = values[cursor:cursor + 3]
        cursor += 3
        if not MIN_KEY <= key <= MAX_KEY:
            return INVALID_RESULT, b""

        if opcode == 0:  # Put(key, value)
            if (not MIN_VALUE <= value <= MAX_VALUE
                    or key in seen_put_keys):
                return INVALID_RESULT, b""
            seen_put_keys.add(key)
            if len(cache) == capacity:
                evicted = lru_to_mru.pop(0)
                del cache[evicted]
            cache[key] = value
            lru_to_mru.append(key)
            records.extend((opcode, 0))
        elif opcode == 1:  # Get(key)
            if value != 0 or key not in cache:
                return INVALID_RESULT, b""
            cached_value = cache[key]
            lru_to_mru.remove(key)
            lru_to_mru.append(key)
            records.extend((opcode, 1, cached_value))
        else:
            return INVALID_RESULT, b""

    records.extend((2, len(lru_to_mru)))
    for key in lru_to_mru:
        records.extend((key, cache[key]))
    output = b"".join(struct.pack("<q", value) for value in records)

    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
