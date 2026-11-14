"""Bounded linked fixed-array block-list oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

BLOCK_SIZE = 4
MAX_INITIAL_ITEMS = 16
MAX_OPERATIONS = 64
MAX_INSERTS = 32
MAX_ACCESSES = 32
MAX_ITEMS = MAX_INITIAL_ITEMS + MAX_INSERTS
MAX_INPUT_LENGTH = 1 + MAX_INITIAL_ITEMS + 1 + 3 * MAX_INSERTS + 2 * MAX_ACCESSES
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_ACCESSES
WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, ...], tuple[tuple[int, ...], ...], int] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    initial_count = values[0]
    if not 0 <= initial_count <= MAX_INITIAL_ITEMS or len(values) < initial_count + 2:
        return None
    initial = tuple(values[1:1 + initial_count])
    if any(not -1_000_000 <= value <= 1_000_000 for value in initial):
        return None
    operation_count = values[1 + initial_count]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    cursor = 2 + initial_count
    current_size = initial_count
    insert_count = access_count = 0
    operations: list[tuple[int, ...]] = []
    for _ in range(operation_count):
        if cursor >= len(values):
            return None
        opcode = values[cursor]
        if opcode == 0:
            if cursor + 3 > len(values):
                return None
            index, value = values[cursor + 1], values[cursor + 2]
            if not 0 <= index <= current_size or not -1_000_000 <= value <= 1_000_000:
                return None
            insert_count += 1
            if insert_count > MAX_INSERTS:
                return None
            current_size += 1
            operations.append((0, index, value))
            cursor += 3
        elif opcode == 1:
            if cursor + 2 > len(values):
                return None
            index = values[cursor + 1]
            if not 0 <= index < current_size:
                return None
            access_count += 1
            if access_count > MAX_ACCESSES:
                return None
            operations.append((1, index))
            cursor += 2
        else:
            return None
    if cursor != len(values):
        return None
    if current_size > MAX_ITEMS:
        return None
    return initial, tuple(operations), access_count


class _BlockList:
    """Small indexed sequence represented by linked blocks with split-on-overflow."""

    def __init__(self) -> None:
        self.items: list[list[int]] = [[]]
        self.next: list[int] = [-1]

    def insert(self, index: int, value: int) -> None:
        node = 0
        offset = 0
        while self.next[node] != -1 and index > offset + len(self.items[node]):
            offset += len(self.items[node])
            node = self.next[node]
        block = self.items[node]
        local = index - offset
        block.insert(local, value)
        if len(block) > 2 * BLOCK_SIZE:
            new_node = len(self.items)
            moved = block[-BLOCK_SIZE:]
            del block[-BLOCK_SIZE:]
            self.items.append(moved)
            self.next.append(self.next[node])
            self.next[node] = new_node

    def get(self, index: int) -> int:
        node = 0
        offset = 0
        while index >= offset + len(self.items[node]):
            offset += len(self.items[node])
            node = self.next[node]
        return self.items[node][index - offset]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    initial, operations, access_count = parsed
    if access_count:
        if type(output_is_null) is not bool:
            return CAPACITY_ERROR, b""
        effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
        required = 8 * access_count
        if (type(effective_capacity) is not int or effective_capacity < required
                or output_is_null):
            return CAPACITY_ERROR, b""
    sequence = _BlockList()
    for value in initial:
        sequence.insert(sum(len(block) for block in sequence.items), value)
    answers: list[int] = []
    for operation in operations:
        if operation[0] == 0:
            sequence.insert(operation[1], operation[2])
        else:
            answers.append(sequence.get(operation[1]))
    payload = b"".join(struct.pack("<q", value) for value in answers)
    return len(payload), payload


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]
