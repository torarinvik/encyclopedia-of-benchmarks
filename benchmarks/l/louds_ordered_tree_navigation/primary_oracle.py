"""Primary bounded reference for LOUDS ordered-tree navigation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_Q = 32
MAX_VALID_INPUT_LENGTH = 2 + (MAX_N - 1) + 3 * MAX_Q
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (4 + MAX_Q)
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int]):
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, query_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= query_count <= MAX_Q:
        return None
    if len(values) != 2 + (n - 1) + 3 * query_count:
        return None
    parents = [0]
    for vertex in range(1, n):
        parent = values[1 + vertex]
        if not 0 <= parent < vertex:
            return None
        parents.append(parent)
    queries: list[tuple[int, int, int]] = []
    offset = 1 + n
    for query in range(query_count):
        opcode, node, argument = values[offset + 3 * query:offset + 3 * query + 3]
        if not 0 <= node < n:
            return None
        if opcode in (0, 1):
            if argument != 0:
                return None
        elif opcode == 2:
            if not 0 <= argument <= n:
                return None
        else:
            return None
        queries.append((opcode, node, argument))
    return n, parents, queries


def _louds(parents: list[int]) -> tuple[int, int]:
    n = len(parents)
    children: list[list[int]] = [[] for _ in range(n)]
    for vertex in range(1, n):
        children[parents[vertex]].append(vertex)

    order = [0]
    degrees: list[int] = []
    for cursor in range(n):
        vertex = order[cursor]
        degrees.append(len(children[vertex]))
        order.extend(children[vertex])

    packed = 0
    position = 0
    for degree in degrees:
        for _ in range(degree):
            packed |= 1 << position
            position += 1
        position += 1  # zero terminates this node's unary degree code
    return packed, position


def _decode_degrees(packed: int, bit_length: int, n: int) -> list[int]:
    zero_positions = [position for position in range(bit_length)
                      if packed & (1 << position) == 0]
    degrees: list[int] = []
    previous_zero = -1
    for node in range(n):
        zero = zero_positions[node]  # select_0(node)
        degrees.append(zero - previous_zero - 1)
        previous_zero = zero
    return degrees


def _answer_queries(packed: int, bit_length: int, n: int,
                    queries: list[tuple[int, int, int]]) -> list[int]:
    degrees = _decode_degrees(packed, bit_length, n)
    rank_prefix = [0]
    for degree in degrees:
        rank_prefix.append(rank_prefix[-1] + degree)

    answers: list[int] = []
    for opcode, node, argument in queries:
        if opcode == 0:
            answers.append(degrees[node])
        elif opcode == 1:
            parent = -1
            if node != 0:
                for candidate in range(n):
                    if rank_prefix[candidate + 1] >= node:
                        parent = candidate
                        break
            answers.append(parent)
        else:
            first_child = 1 + rank_prefix[node]
            answers.append(first_child + argument if argument < degrees[node] else -1)
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
    packed, bit_length = _louds(parents)
    answers = _answer_queries(packed, bit_length, n, queries)
    words = (n, bit_length, packed, len(queries), *answers)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
