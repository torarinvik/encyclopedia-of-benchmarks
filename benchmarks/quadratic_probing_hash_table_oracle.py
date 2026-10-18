"""Oracle for the bounded source-faithful quadratic-probing table."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_INITIAL_CAPACITY = 1
MAX_INITIAL_CAPACITY = 8
MAX_TABLE_CAPACITY = 64
MAX_OPERATIONS = 24
MIN_KEY = 1
MAX_KEY = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 3 + (MAX_OPERATIONS - MAX_TABLE_CAPACITY // 4) + MAX_TABLE_CAPACITY
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
INVALID_RESULT = -1
OUTPUT_ERROR = -2

OP_INSERT = 0
OP_REMOVE = 1
OP_FIND = 2


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None

    capacity, operation_count = values[:2]
    if not MIN_INITIAL_CAPACITY <= capacity <= MAX_INITIAL_CAPACITY:
        return None
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 2 + 2 * operation_count:
        return None

    operations: list[tuple[int, int]] = []
    for offset in range(2, len(values), 2):
        operation, key = values[offset:offset + 2]
        if operation not in (OP_INSERT, OP_REMOVE, OP_FIND):
            return None
        if not MIN_KEY <= key <= MAX_KEY:
            return None
        operations.append((operation, key))
    return capacity, operations


def _insert_slot(table: list[int], key: int) -> int | None:
    capacity = len(table)
    for probe in range(capacity * 100):
        index = (key + probe * probe) % capacity
        if table[index] in (0, -1):
            return index
    return None


def _find_slot(table: list[int], key: int) -> int | None:
    capacity = len(table)
    for probe in range(capacity * 100):
        index = (key + probe * probe) % capacity
        slot = table[index]
        if slot == 0:
            return None
        if slot == key:
            return index
    return None


def _simulate(values: Sequence[int] | None):
    parsed = _parse(values)
    if parsed is None:
        return None
    capacity, operations = parsed
    table = [0] * capacity
    active: set[int] = set()
    size = 0
    find_results: list[int] = []

    def rehash() -> bool:
        nonlocal table, size
        old_table = table
        table = [0] * (2 * len(old_table))
        if len(table) > MAX_TABLE_CAPACITY:
            return False
        for old_key in old_table:
            if old_key in (0, -1):
                continue
            size -= 1
            if not place_and_maybe_rehash(old_key):
                return False
        return True

    def place_and_maybe_rehash(key: int) -> bool:
        nonlocal size
        index = _insert_slot(table, key)
        if index is None:
            return False
        table[index] = key
        size += 1
        if size / len(table) >= 0.5:
            return rehash()
        return True

    for operation, key in operations:
        if operation == OP_INSERT:
            if key in active:
                return None
            if not place_and_maybe_rehash(key):
                # The source returns its empty-slot sentinel on exhaustion and
                # add() then writes to slot zero. That fallback is outside the
                # valid benchmark domain.
                return None
            active.add(key)

        elif operation == OP_REMOVE:
            if key not in active:
                return None
            index = _find_slot(table, key)
            if index is None:
                return None
            table[index] = -1
            active.remove(key)
            size -= 1

        else:
            index = _find_slot(table, key)
            # The pinned find() method treats index zero as the not-present
            # sentinel, even when that slot contains the requested key.
            find_results.append(0 if index is None or index == 0 else table[index])

    words = [len(table), size, len(find_results), *find_results, *table]
    output = struct.pack("<" + "q" * len(words), *words)
    if len(output) > MAX_OUTPUT_BYTES:
        return None
    return output


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return serialized table state or the documented ABI error."""
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

    output = _simulate(values)
    if output is None:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
