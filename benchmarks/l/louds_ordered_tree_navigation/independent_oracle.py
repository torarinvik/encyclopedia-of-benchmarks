"""Independent direct-tree reference for LOUDS navigation traces."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_Q = 32
MAX_INPUT_LENGTH = 2 + (MAX_N - 1) + 3 * MAX_Q + 1
MAX_OUTPUT_BYTES = 8 * (4 + MAX_Q)


def _read(values: Sequence[int]):
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    count, requests = values[0], values[1]
    if not 1 <= count <= MAX_N or not 0 <= requests <= MAX_Q:
        return None
    if len(values) != 2 + count - 1 + 3 * requests:
        return None
    parent = [-1] + list(values[2:2 + count - 1])
    child_lists: list[list[int]] = [[] for _ in range(count)]
    for vertex in range(1, count):
        if not 0 <= parent[vertex] < vertex:
            return None
        child_lists[parent[vertex]].append(vertex)
    ops: list[tuple[int, int, int]] = []
    start = 2 + count - 1
    for index in range(requests):
        op, node, arg = values[start + 3 * index:start + 3 * index + 3]
        if not 0 <= node < count:
            return None
        if op in (0, 1):
            if arg != 0:
                return None
        elif op == 2:
            if not 0 <= arg <= count:
                return None
        else:
            return None
        ops.append((op, node, arg))
    return count, parent, child_lists, ops


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    n, parent, child_lists, queries = parsed

    level_order = [0]
    for vertex in level_order:
        level_order.extend(child_lists[vertex])
    level_id = [0] * n
    for index, vertex in enumerate(level_order):
        level_id[vertex] = index
    degrees = [len(child_lists[vertex]) for vertex in level_order]

    packed = 0
    bit_length = 0
    for degree in degrees:
        for _ in range(degree):
            packed |= 1 << bit_length
            bit_length += 1
        bit_length += 1

    answers: list[int] = []
    for opcode, node, argument in queries:
        original = level_order[node]
        if opcode == 0:
            answers.append(len(child_lists[original]))
        elif opcode == 1:
            answers.append(-1 if original == 0 else level_id[parent[original]])
        elif argument < len(child_lists[original]):
            child = child_lists[original][argument]
            answers.append(level_id[child])
        else:
            answers.append(-1)

    payload = b"".join(struct.pack("<q", word)
                       for word in (n, bit_length, packed, len(queries), *answers))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
