"""Oracle for the bounded Java LinearProbingHashMap trace."""
from __future__ import annotations
from collections.abc import Sequence
import struct

MAX_OPERATIONS = 32
MAX_INITIAL_CAPACITY = 16
MAX_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 2560
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def _hash(key: int, capacity: int) -> int:
    return (key & 0x7FFFFFFF) % capacity


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
    if any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return INVALID_RESULT, b""

    initial_capacity, op_count = values[0], values[1]
    if not 4 <= initial_capacity <= MAX_INITIAL_CAPACITY or not 0 <= op_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""
    keys: list[int | None] = [None] * initial_capacity
    mapped: list[int | None] = [None] * initial_capacity
    size = 0
    records: list[int] = []
    pos = 2

    def resize(new_capacity: int) -> None:
        nonlocal keys, mapped
        old_keys, old_values = keys, mapped
        keys = [None] * new_capacity
        mapped = [None] * new_capacity
        for key, value in zip(old_keys, old_values):
            if key is not None:
                index = _hash(key, new_capacity)
                while keys[index] is not None:
                    index = (index + 1) % new_capacity
                keys[index], mapped[index] = key, value

    def put(key: int, value: int) -> bool:
        nonlocal size
        if size > len(keys) // 2:
            resize(len(keys) * 2)
        index = _hash(key, len(keys))
        while keys[index] is not None:
            if keys[index] == key:
                mapped[index] = value
                return True
            index = (index + 1) % len(keys)
        keys[index], mapped[index] = key, value
        size += 1
        return True

    def locate(key: int) -> int:
        index = _hash(key, len(keys))
        while keys[index] is not None:
            if keys[index] == key:
                return index
            index = (index + 1) % len(keys)
        return -1

    def delete(key: int) -> bool:
        nonlocal size
        index = locate(key)
        if index < 0:
            return False
        keys[index] = None
        mapped[index] = None
        index = (index + 1) % len(keys)
        while keys[index] is not None:
            rehash_key, rehash_value = keys[index], mapped[index]
            keys[index] = None
            mapped[index] = None
            size -= 1
            put(rehash_key, rehash_value)  # type: ignore[arg-type]
            index = (index + 1) % len(keys)
        size -= 1
        if size > 0 and size <= len(keys) // 8:
            resize(len(keys) // 2)
        return True

    for _ in range(op_count):
        if pos >= len(values):
            return INVALID_RESULT, b""
        opcode = values[pos]
        pos += 1
        if opcode == 0:
            if pos + 1 >= len(values):
                return INVALID_RESULT, b""
            key, value = values[pos], values[pos + 1]
            pos += 2
            if not I32_MIN <= key <= I32_MAX or not I32_MIN <= value <= I32_MAX:
                return INVALID_RESULT, b""
            put(key, value)
            records.extend((0, 1))
        elif opcode in (1, 2, 3):
            if pos >= len(values):
                return INVALID_RESULT, b""
            key = values[pos]
            pos += 1
            if not I32_MIN <= key <= I32_MAX:
                return INVALID_RESULT, b""
            index = locate(key)
            if opcode == 1:
                records.extend((1, 1, 0) if index < 0 else (1, 0, mapped[index]))
            elif opcode == 2:
                records.extend((2, int(delete(key))))
            else:
                records.extend((3, int(index >= 0)))
        elif opcode == 4:
            records.extend((4, size))
        elif opcode == 5:
            present = sorted(key for key in keys if key is not None)
            records.extend((5, len(present), *present))
        else:
            return INVALID_RESULT, b""
    if pos != len(values):
        return INVALID_RESULT, b""

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", word) for word in records)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
