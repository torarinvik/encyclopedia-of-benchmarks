"""Reference model for the bounded GBBS Goodrich--Pszona order profile."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 20
MAX_EDGES = MAX_NODES * (MAX_NODES - 1) // 2
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None) -> tuple[int, list[set[int]]] | None:
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    adj = [set() for _ in range(n)]
    for pos in range(2, len(values), 2):
        u, v = values[pos:pos + 2]
        if not 0 <= u < v < n or v in adj[u]:
            return None
        adj[u].add(v)
        adj[v].add(u)
    return n, adj


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or not isinstance(values, (tuple, list))
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    n, adjacency = parsed
    output_bytes = 8 * n
    if output_is_null or output_capacity is not None and output_capacity < output_bytes:
        return OUTPUT_ERROR, b""

    remaining = set(range(n))
    order: list[int] = []
    while remaining:
        # Sorting the active induced degree sequence models integer_sort_inplace
        # for ns=1, with a deterministic vertex-ID refinement for equal keys.
        degree_order = sorted(
            remaining,
            key=lambda vertex: (sum(neighbor in remaining for neighbor in adjacency[vertex]), vertex),
        )
        vertex = degree_order[0]
        order.append(vertex)
        remaining.remove(vertex)
    rank = [0] * n
    for position, vertex in enumerate(order):
        rank[vertex] = position
    return output_bytes, b"".join(struct.pack("<q", value) for value in rank)


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    return expected_output(values)
