"""Independent tree/string reference for bounded BP navigation queries."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 31
MAX_Q = 32
MAX_INPUT_LENGTH = 2 + (MAX_N - 1) + 3 * MAX_Q + 1
MAX_OUTPUT_BYTES = 8 * (4 + MAX_Q)


def _decode(values: Sequence[int]):
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    n, q = values[0], values[1]
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
    operations: list[tuple[int, int, int]] = []
    offset = n + 1
    length = 2 * n
    for index in range(q):
        opcode, first, second = values[offset + 3 * index:offset + 3 * index + 3]
        if opcode in (0, 1):
            if not 0 <= first <= length or not -length <= second <= length:
                return None
        elif opcode == 2:
            if not 0 <= first <= second < length:
                return None
        elif opcode in (3, 4, 5):
            if not 0 <= first < length or second != 0:
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return parent, children, operations


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
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    parent, children, operations = parsed
    n = len(parent)
    bits: list[int] = []
    opens = [-1] * n
    closes = [-1] * n
    enclosing = [-1] * n
    stack: list[tuple[int, int]] = [(0, 0)]
    while stack:
        node, child_cursor = stack[-1]
        if child_cursor == 0:
            opens[node] = len(bits)
            bits.append(1)
        if child_cursor < len(children[node]):
            child = children[node][child_cursor]
            stack[-1] = (node, child_cursor + 1)
            enclosing[child] = opens[node]
            stack.append((child, 0))
        else:
            closes[node] = len(bits)
            bits.append(0)
            stack.pop()

    excess = [0]
    for bit in bits:
        excess.append(excess[-1] + (1 if bit else -1))
    answers: list[int] = []
    for opcode, first, second in operations:
        if opcode == 0:
            target = excess[first] + second
            answer = next((position for position in range(first + 1, len(excess))
                           if excess[position] == target), len(bits) + 1)
        elif opcode == 1:
            target = excess[first] + second
            answer = next((position for position in range(first - 1, -1, -1)
                           if excess[position] == target), 0)
        elif opcode == 2:
            answer = min(range(first, second + 1), key=lambda position: (excess[position + 1], position))
        elif opcode == 3:
            node = next((node for node in range(n) if opens[node] == first), None)
            if node is None:
                return -1, b""
            answer = closes[node]
        elif opcode == 4:
            node = next((node for node in range(n) if closes[node] == first), None)
            if node is None:
                return -1, b""
            answer = opens[node]
        else:
            node = next((node for node in range(n) if opens[node] == first), None)
            if node is None:
                return -1, b""
            answer = enclosing[node]
        answers.append(answer)
    packed = sum(bit << index for index, bit in enumerate(bits))
    payload = b"".join(struct.pack("<q", word)
                       for word in (n, len(bits), packed, len(operations), *answers))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
