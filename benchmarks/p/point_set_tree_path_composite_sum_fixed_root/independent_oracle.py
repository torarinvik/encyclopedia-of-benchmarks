"""Independent full fixed-root DP recomputation after each update."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MAX_Q,
        MODULUS, OUTPUT_ERROR,
    )
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MAX_Q,
        MODULUS, OUTPUT_ERROR,
    )


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    cursor = 2
    vertex_values = list(values[cursor:cursor + n])
    cursor += n
    if len(vertex_values) != n or any(not 0 <= value < MODULUS for value in vertex_values):
        return None
    edges = []
    dsu = list(range(n))

    def find(x: int) -> int:
        while dsu[x] != x:
            dsu[x] = dsu[dsu[x]]
            x = dsu[x]
        return x

    for _ in range(n - 1):
        if cursor + 4 > len(values):
            return None
        u, v, b, c = values[cursor:cursor + 4]
        cursor += 4
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 1 <= b < MODULUS or not 0 <= c < MODULUS):
            return None
        ru, rv = find(u), find(v)
        if ru == rv:
            return None
        dsu[rv] = ru
        edges.append([u, v, b, c])
    if len({find(v) for v in range(n)}) != 1:
        return None
    operations = []
    for _ in range(q):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        if kind == 0 and cursor + 3 <= len(values):
            vertex, value = values[cursor + 1:cursor + 3]
            if not 0 <= vertex < n or not 0 <= value < MODULUS:
                return None
            operations.append((0, vertex, value))
            cursor += 3
        elif kind == 1 and cursor + 4 <= len(values):
            edge, b, c = values[cursor + 1:cursor + 4]
            if not 0 <= edge < n - 1 or not 1 <= b < MODULUS or not 0 <= c < MODULUS:
                return None
            operations.append((1, edge, b, c))
            cursor += 4
        else:
            return None
    if cursor != len(values):
        return None
    return n, vertex_values, edges, operations


def _recompute(n: int, vertex_values: list[int], edges: list[list[int]]) -> int:
    graph: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for edge_id, (u, v, _b, _c) in enumerate(edges):
        graph[u].append((v, edge_id))
        graph[v].append((u, edge_id))
    parent = [-2] * n
    parent[0] = -1
    order = [0]
    for u in order:
        for v, _edge_id in graph[u]:
            if v != parent[u]:
                parent[v] = u
                order.append(v)
    sums = [0] * n
    sizes = [1] * n
    for u in reversed(order):
        total = vertex_values[u]
        size = 1
        for v, edge_id in graph[u]:
            if parent[v] == u:
                _eu, _ev, b, c = edges[edge_id]
                total += b * sums[v] + c * sizes[v]
                size += sizes[v]
        sums[u] = total % MODULUS
        sizes[u] = size
    return sums[0]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, vertex_values, edges, operations = parsed
    byte_count = 8 * len(operations)
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    if output_is_null or (output_capacity is not None and output_capacity < byte_count):
        return OUTPUT_ERROR, b""
    results = []
    for operation in operations:
        if operation[0] == 0:
            _, vertex, value = operation
            vertex_values[vertex] = value
        else:
            _, edge_id, b, c = operation
            edges[edge_id][2] = b
            edges[edge_id][3] = c
        results.append(_recompute(n, vertex_values, edges))
    return byte_count, b"".join(struct.pack("<q", value) for value in results)
