"""Primary deletion-contraction oracle for bounded chromatic polynomials."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_VERTICES = 8
MAX_EDGES = 16
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (MAX_VERTICES + 1)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _delete_contract(adjacency: tuple[int, ...], n: int) -> tuple[int, ...]:
    edge: tuple[int, int] | None = None
    for u in range(n):
        neighbors = adjacency[u] & ~((1 << (u + 1)) - 1)
        if neighbors:
            bit = neighbors & -neighbors
            v = bit.bit_length() - 1
            edge = (u, v)
            break
    if edge is None:
        coefficients = [0] * (MAX_VERTICES + 1)
        coefficients[n] = 1
        return tuple(coefficients)

    u, v = edge
    deleted = list(adjacency)
    deleted[u] &= ~(1 << v)
    deleted[v] &= ~(1 << u)
    without_edge = _delete_contract(tuple(deleted), n)

    def remap(vertex: int) -> int:
        if vertex == v:
            vertex = u
        if vertex > v:
            vertex -= 1
        return vertex

    contracted = [0] * MAX_VERTICES
    for left in range(n):
        for right in range(left + 1, n):
            if not (adjacency[left] >> right) & 1 or (left == u and right == v):
                continue
            new_left = remap(left)
            new_right = remap(right)
            if new_left == new_right:
                continue
            contracted[new_left] |= 1 << new_right
            contracted[new_right] |= 1 << new_left
    with_edge_contracted = _delete_contract(tuple(contracted), n - 1)
    return tuple(without_edge[i] - with_edge_contracted[i]
                 for i in range(MAX_VERTICES + 1))


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    n, m = values[:2]
    if not 0 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return INVALID_RESULT, b""
    adjacency = [0] * n
    edges: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return INVALID_RESULT, b""
        edge = (min(u, v), max(u, v))
        if edge in edges:
            return INVALID_RESULT, b""
        edges.add(edge)
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u
    coefficients = _delete_contract(tuple(adjacency) + (0,) * (MAX_VERTICES - n), n)
    payload = b"".join(struct.pack("<q", coefficients[index]) for index in range(n + 1))
    needed = len(payload)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null or effective_capacity < needed):
        return OUTPUT_ERROR, b""
    return needed, payload
