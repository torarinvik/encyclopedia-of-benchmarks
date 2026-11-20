"""Bucket-chain reference for a bounded rotating hashbelt."""

from __future__ import annotations

from collections.abc import Sequence

TABLES = 4
BUCKETS = 8
MAX_KEYS = 32
MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS + 1
MAX_OUTPUT_BYTES = MAX_OPERATIONS * 8
WORKSPACE_BYTES = 4096
MISS = -(1 << 31)


def _parse(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 3 * count:
        return None
    operations: list[tuple[int, int, int]] = []
    for op_index in range(count):
        opcode, key, argument = values[1 + 3 * op_index:4 + 3 * op_index]
        if opcode == 0:
            if not 0 <= key < MAX_KEYS or not -1000 <= argument <= 1000:
                return None
        elif opcode == 1:
            if not 0 <= key < MAX_KEYS or argument != 0:
                return None
        elif opcode == 2:
            if key != 0 or argument != 0:
                return None
        else:
            return None
        operations.append((opcode, key, argument))
    return operations


def _run_bucket_chains(operations: list[tuple[int, int, int]]) -> list[int]:
    heads = [[-1] * BUCKETS for _ in range(TABLES)]
    keys = [[-1] * MAX_KEYS for _ in range(TABLES)]
    values = [[0] * MAX_KEYS for _ in range(TABLES)]
    links = [[-1] * MAX_KEYS for _ in range(TABLES)]
    used = [0] * TABLES
    newest = 0
    output: list[int] = []

    def locate(table: int, key: int) -> int:
        node = heads[table][key % BUCKETS]
        while node >= 0:
            if keys[table][node] == key:
                return node
            node = links[table][node]
        return -1

    def put_head(key: int, value: int) -> None:
        table = newest
        node = locate(table, key)
        if node >= 0:
            values[table][node] = value
            return
        node = next(index for index in range(MAX_KEYS) if keys[table][index] < 0)
        used[table] += 1
        bucket = key % BUCKETS
        keys[table][node] = key
        values[table][node] = value
        links[table][node] = heads[table][bucket]
        heads[table][bucket] = node

    def remove(table: int, key: int, node: int) -> None:
        bucket = key % BUCKETS
        previous = -1
        cursor = heads[table][bucket]
        while cursor != node:
            previous = cursor
            cursor = links[table][cursor]
        if previous < 0:
            heads[table][bucket] = links[table][node]
        else:
            links[table][previous] = links[table][node]
        keys[table][node] = -1
        values[table][node] = 0
        links[table][node] = -1
        used[table] -= 1

    def find(key: int) -> tuple[int, int, int]:
        for age in range(TABLES):
            table = (newest + age) % TABLES
            node = locate(table, key)
            if node >= 0:
                return table, node, values[table][node]
        return -1, -1, MISS

    for opcode, key, argument in operations:
        if opcode == 0:
            old_table, old_node, _ = find(key)
            put_head(key, argument)
            if old_table >= 0 and old_table != newest:
                # The insertion above creates the new generation's entry.
                # Remove the old copy so the key has exactly one live copy.
                remove(old_table, key, old_node)
            output.append(1 if old_table < 0 else 0)
        elif opcode == 1:
            table, node, value = find(key)
            if table >= 0 and table != newest:
                remove(table, key, node)
                put_head(key, value)
            output.append(value)
        else:
            oldest = (newest + TABLES - 1) % TABLES
            dropped = used[oldest]
            heads[oldest] = [-1] * BUCKETS
            keys[oldest] = [-1] * MAX_KEYS
            used[oldest] = 0
            newest = oldest
            output.append(dropped)
    return output


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
    result = b"".join(value.to_bytes(8, "little", signed=True)
                      for value in _run_bucket_chains(operations))
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
