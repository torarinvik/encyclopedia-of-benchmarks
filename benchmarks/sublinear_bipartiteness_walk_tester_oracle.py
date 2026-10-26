"""Primary adjacency-list oracle for the bounded-degree walk tester profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_D = 4
MAX_EDGES = 32
MAX_T = 4
MAX_R = 8
MAX_L = 8
MAX_INPUT = 330


def _pack(value: int) -> bytes:
    return struct.pack("<q", value)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))
            or len(values) < 8 or len(values) > MAX_INPUT
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, degree_bound, edge_count = values[:3]
    if (not 1 <= n <= MAX_N or not 3 <= degree_bound <= MAX_D
            or not 0 <= edge_count <= min(MAX_EDGES, n * degree_bound // 2)):
        return -1, b""
    suffix = 3 + 2 * edge_count
    if len(values) < suffix + 4:
        return -1, b""
    start_count, walk_count, walk_length = values[suffix:suffix + 3]
    if (not 1 <= start_count <= MAX_T or not 1 <= walk_count <= MAX_R
            or not 1 <= walk_length <= MAX_L):
        return -1, b""
    if len(values) != suffix + 3 + start_count + start_count * walk_count * walk_length:
        return -1, b""

    neighbors: list[list[int]] = [[] for _ in range(n)]
    seen_edges: set[tuple[int, int]] = set()
    for index in range(edge_count):
        left, right = values[3 + 2 * index:5 + 2 * index]
        edge = (left, right)
        if not 0 <= left < right < n or edge in seen_edges:
            return -1, b""
        seen_edges.add(edge)
        neighbors[left].append(right)
        neighbors[right].append(left)
    for row in neighbors:
        row.sort()
        if len(row) > degree_bound:
            return -1, b""
    starts_at = suffix + 3
    draws_at = starts_at + start_count
    starts = list(values[starts_at:draws_at])
    if any(not 0 <= start < n for start in starts):
        return -1, b""
    draw_count = start_count * walk_count * walk_length
    draws = values[draws_at:draws_at + draw_count]
    if any(not 0 <= choice < 2 * degree_bound for choice in draws):
        return -1, b""

    accepted = 1
    at = 0
    for start in starts:
        parity_seen = [0] * n
        parity_seen[start] |= 1
        for _ in range(walk_count):
            vertex = start
            parity = 0
            for _ in range(walk_length):
                choice = draws[at]
                at += 1
                if choice < len(neighbors[vertex]):
                    vertex = neighbors[vertex][choice]
                    parity ^= 1
                parity_seen[vertex] |= 1 << parity
                if parity_seen[vertex] == 3:
                    accepted = 0
                    break
            if not accepted:
                break
        if not accepted:
            break
    payload = _pack(accepted)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
