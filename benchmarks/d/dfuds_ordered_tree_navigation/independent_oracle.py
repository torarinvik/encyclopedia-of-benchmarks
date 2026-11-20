"""Independent direct-tree reference for DFUDS navigation traces."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 31
MAX_Q = 32
MAX_INPUT_LENGTH = 2 + (MAX_N - 1) + 3 * MAX_Q + 1
MAX_OUTPUT_BYTES = 8 * (4 + MAX_Q)


def _read(values: Sequence[int]):
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 2 + n - 1 + 3 * q:
        return None
    parent = [-1] + list(values[2:2 + n - 1])
    children: list[list[int]] = [[] for _ in range(n)]
    for node in range(1, n):
        if not 0 <= parent[node] < node:
            return None
        children[parent[node]].append(node)
    queries: list[tuple[int, int, int]] = []
    offset = n + 1
    for index in range(q):
        opcode, node, argument = values[offset + 3 * index:offset + 3 * index + 3]
        if not 0 <= node < n:
            return None
        if opcode in (0, 2):
            if argument != 0:
                return None
        elif opcode == 1:
            if not 0 <= argument <= n:
                return None
        else:
            return None
        queries.append((opcode, node, argument))
    return parent, children, queries


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
    parent, children, queries = parsed
    n = len(parent)

    order: list[int] = []
    stack = [0]
    while stack:
        node = stack.pop()
        order.append(node)
        for child in reversed(children[node]):
            stack.append(child)
    preorder_id = [0] * n
    for index, node in enumerate(order):
        preorder_id[node] = index

    bits = [1]
    for node in order:
        bits.extend([1] * len(children[node]))
        bits.append(0)
    answers: list[int] = []
    for opcode, node_id, argument in queries:
        vertex = order[node_id]
        if opcode == 0:
            answer = len(children[vertex])
        elif opcode == 1:
            if argument >= len(children[vertex]):
                answer = -1
            else:
                answer = preorder_id[children[vertex][argument]]
        else:
            answer = -1 if vertex == 0 else preorder_id[parent[vertex]]
        answers.append(answer)

    packed = sum(bit << index for index, bit in enumerate(bits))
    payload = b"".join(struct.pack("<q", word)
                       for word in (n, len(bits), packed, len(queries), *answers))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
