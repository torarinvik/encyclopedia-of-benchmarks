"""Primary bounded reference for BP excess-search and tree navigation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 31
MAX_Q = 32
MAX_VALID_INPUT_LENGTH = 2 + (MAX_N - 1) + 3 * MAX_Q
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (4 + MAX_Q)
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int]):
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 2 + (n - 1) + 3 * q:
        return None
    parents = [0]
    for vertex in range(1, n):
        parent = values[1 + vertex]
        if not 0 <= parent < vertex:
            return None
        parents.append(parent)
    queries: list[tuple[int, int, int]] = []
    offset = n + 1
    bit_length = 2 * n
    for query in range(q):
        opcode, first, second = values[offset + 3 * query:offset + 3 * query + 3]
        if opcode in (0, 1):
            # Search indices address excess prefixes E[0..2n].
            if not 0 <= first <= bit_length or not -bit_length <= second <= bit_length:
                return None
        elif opcode == 2:
            if not 0 <= first <= second < bit_length:
                return None
        elif opcode in (3, 4, 5):
            if not 0 <= first < bit_length or second != 0:
                return None
        else:
            return None
        queries.append((opcode, first, second))
    return n, parents, queries


def _encode_bp(parents: list[int]) -> list[int]:
    n = len(parents)
    children: list[list[int]] = [[] for _ in range(n)]
    for vertex in range(1, n):
        children[parents[vertex]].append(vertex)

    bits: list[int] = []
    stack: list[tuple[int, int]] = [(0, 0)]
    bits.append(1)
    while stack:
        node, next_child = stack[-1]
        if next_child < len(children[node]):
            child = children[node][next_child]
            stack[-1] = (node, next_child + 1)
            bits.append(1)
            stack.append((child, 0))
        else:
            bits.append(0)
            stack.pop()
    return bits


def _answers(bits: list[int], queries: list[tuple[int, int, int]]) -> list[int] | None:
    bit_length = len(bits)
    excess = [0] * (bit_length + 1)
    for position, bit in enumerate(bits):
        excess[position + 1] = excess[position] + (1 if bit else -1)
    answers: list[int] = []
    for opcode, first, second in queries:
        if opcode == 0:
            target = excess[first] + second
            answers.append(next((index for index in range(first + 1, bit_length + 1)
                                 if excess[index] == target), bit_length + 1))
        elif opcode == 1:
            target = excess[first] + second
            answers.append(next((index for index in range(first - 1, -1, -1)
                                 if excess[index] == target), 0))
        elif opcode == 2:
            # RMQi returns the leftmost position of minimum excess in [l,r].
            best = first
            for position in range(first + 1, second + 1):
                if excess[position + 1] < excess[best + 1]:
                    best = position
            answers.append(best)
        elif opcode == 3:
            if bits[first] != 1:
                return None
            target = excess[first + 1] - 1
            match = next((index for index in range(first + 2, bit_length + 1)
                          if excess[index] == target), None)
            if match is None:
                return None
            answers.append(match - 1)
        elif opcode == 4:
            if bits[first] != 0:
                return None
            target = excess[first + 1]
            match = next((index for index in range(first, -1, -1)
                          if excess[index] == target), None)
            if match is None:
                return None
            answers.append(match)
        else:
            if bits[first] != 1:
                return None
            if first == 0:
                answers.append(-1)
            else:
                target = excess[first + 1] - 2
                answer = next((index for index in range(first, -1, -1)
                               if excess[index] == target), -1)
                answers.append(answer)
    return answers


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, parents, queries = parsed
    bits = _encode_bp(parents)
    answers = _answers(bits, queries)
    if answers is None:
        return -1, b""
    packed = sum(bit << index for index, bit in enumerate(bits))
    words = (n, len(bits), packed, len(queries), *answers)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
