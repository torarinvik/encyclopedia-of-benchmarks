"""Primary bounded reference for DFUDS ordered-tree navigation."""

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
    for query in range(q):
        opcode, node, argument = values[offset + 3 * query:offset + 3 * query + 3]
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
    return n, parents, queries


def _preorder(parents: list[int]) -> tuple[list[int], list[list[int]]]:
    n = len(parents)
    children: list[list[int]] = [[] for _ in range(n)]
    for node in range(1, n):
        children[parents[node]].append(node)
    order = [0]
    stack: list[tuple[int, int]] = [(0, 0)]
    while stack:
        node, cursor = stack[-1]
        if cursor < len(children[node]):
            child = children[node][cursor]
            stack[-1] = (node, cursor + 1)
            order.append(child)
            stack.append((child, 0))
        else:
            stack.pop()
    return order, children


def _dfuds(order: list[int], children: list[list[int]]) -> tuple[list[int], list[int], dict[int, int]]:
    bits = [1]  # dummy opening parenthesis
    descriptor_position: list[int] = []
    position_to_node: dict[int, int] = {}
    for node_id, vertex in enumerate(order):
        start = len(bits) + 1  # one-based DFUDS descriptor position
        descriptor_position.append(start)
        position_to_node[start] = node_id
        bits.extend([1] * len(children[vertex]))
        bits.append(0)
    return bits, descriptor_position, position_to_node


def _findclose(bits: list[int], open_position: int) -> int:
    balance = 0
    for position in range(open_position, len(bits) + 1):
        bit = bits[position - 1]
        balance += 1 if bit else -1
        if balance == 0:
            return position
    return len(bits) + 1


def _findopen(bits: list[int], position: int) -> int:
    if bits[position - 1] == 1:
        return position
    balance = 0
    for candidate in range(position, 0, -1):
        bit = bits[candidate - 1]
        balance += -1 if bit else 1
        if balance == 0:
            return candidate
    return 0


def _previous_zero(bits: list[int], position: int) -> int:
    for candidate in range(position - 1, 0, -1):
        if bits[candidate - 1] == 0:
            return candidate
    return 0


def _answer_queries(bits: list[int], descriptors: list[int], position_to_node: dict[int, int],
                    q: int, queries: list[tuple[int, int, int]]) -> list[int] | None:
    n = len(descriptors)
    answers: list[int] = []
    for opcode, node, argument in queries:
        start = descriptors[node]
        zero = start
        while bits[zero - 1] == 1:
            zero += 1
        degree = zero - start
        if opcode == 0:
            answers.append(degree)
        elif opcode == 1:
            if argument >= degree:
                answers.append(-1)
            else:
                # The chapter numbers child rank from 1; the ABI uses 0-based ranks.
                target_open = start + degree - (argument + 1)
                child_start = _findclose(bits, target_open) + 1
                child = position_to_node.get(child_start)
                if child is None:
                    return None
                answers.append(child)
        elif node == 0:
            answers.append(-1)
        else:
            matched_open = _findopen(bits, start - 1)
            parent_position = _previous_zero(bits, matched_open) + 1
            # For a root child the preceding zero is the select-zero sentinel;
            # position 1 is therefore the virtual root descriptor.
            parent_node = 0 if parent_position == 1 else position_to_node.get(parent_position)
            if parent_node is None:
                return None
            answers.append(parent_node)
    if len(answers) != q:
        return None
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
    order, children = _preorder(parents)
    bits, descriptors, position_to_node = _dfuds(order, children)
    answers = _answer_queries(bits, descriptors, position_to_node, len(queries), queries)
    if answers is None:
        return -1, b""
    packed = sum(bit << index for index, bit in enumerate(bits))
    payload = b"".join(struct.pack("<q", word)
                       for word in (n, len(bits), packed, len(queries), *answers))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
