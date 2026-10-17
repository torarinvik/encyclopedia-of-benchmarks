"""Oracle for the bounded, source-faithful Go LFU cache trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_CAPACITY = 2
MAX_CAPACITY = 16
MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * 3 * MAX_OPERATIONS
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the custom trace encoding, or the ABI error result and no bytes.

    The pinned helper never increments an item's frequency. Successful reads
    and duplicate puts therefore move entries to the front of the frequency-1
    list, while a duplicate put's attempted value update is lost. Within the
    accepted capacity range this is an LRU list with immutable stored values.
    """
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID_RESULT, b""

    initial_capacity, operation_count = values[:2]
    if not MIN_CAPACITY <= initial_capacity <= MAX_CAPACITY:
        return INVALID_RESULT, b""
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""

    keys: list[int] = []  # Most recently touched key first.
    stored_values: list[int] = []
    records: list[int] = []
    position = 2

    def touch(index: int) -> None:
        key = keys.pop(index)
        value = stored_values.pop(index)
        keys.insert(0, key)
        stored_values.insert(0, value)

    for _ in range(operation_count):
        if position >= len(values):
            return INVALID_RESULT, b""
        opcode = values[position]
        position += 1

        if opcode == 0:  # Put(key, value)
            if position + 1 >= len(values):
                return INVALID_RESULT, b""
            key, value = values[position], values[position + 1]
            position += 2
            if not I32_MIN <= key <= I32_MAX or not I32_MIN <= value <= I32_MAX:
                return INVALID_RESULT, b""
            try:
                index = keys.index(key)
            except ValueError:
                if len(keys) == initial_capacity:
                    keys.pop()
                    stored_values.pop()
                keys.insert(0, key)
                stored_values.insert(0, value)
            else:
                # The Go method mutates a copied item, then re-reads the old
                # list element in increaseFreq; the new value is not stored.
                touch(index)
            records.append(0)
        elif opcode == 1:  # Get(key)
            if position >= len(values):
                return INVALID_RESULT, b""
            key = values[position]
            position += 1
            if not I32_MIN <= key <= I32_MAX:
                return INVALID_RESULT, b""
            try:
                index = keys.index(key)
            except ValueError:
                records.extend((1, 1, 0))
            else:
                value = stored_values[index]
                touch(index)
                records.extend((1, 0, value))
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
