"""Oracle for the bounded pinned Python Kruskal-2 graph contract."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_VERTEX_COUNT = 1
MAX_VERTEX_COUNT = 16
MAX_EDGE_COUNT = 64
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGE_COUNT
MAX_OUTPUT_BYTES = 4 * (1 + 3 * (MAX_VERTEX_COUNT - 1))
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return ``[edge_count, (u, v, weight)...]`` in accepted-edge order."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    vertex_count, edge_count = values[:2]
    if not MIN_VERTEX_COUNT <= vertex_count <= MAX_VERTEX_COUNT:
        return INVALID_RESULT, b""
    if not 0 <= edge_count <= MAX_EDGE_COUNT:
        return INVALID_RESULT, b""
    if len(values) != 2 + 3 * edge_count:
        return INVALID_RESULT, b""

    edges: list[tuple[int, int, int]] = []
    unique_edges: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 3):
        u, v, weight = values[offset : offset + 3]
        if not 0 <= u < v < vertex_count:
            return INVALID_RESULT, b""
        if (u, v) in unique_edges:
            return INVALID_RESULT, b""
        unique_edges.add((u, v))
        edges.append((u, v, weight))

    if vertex_count == 1:
        if edge_count != 0:
            return INVALID_RESULT, b""
        accepted: list[tuple[int, int, int]] = []
    else:
        # The pinned source pre-adds nodes in ascending order, then inserts
        # edges in input order into insertion-ordered neighbor maps. Its scan
        # therefore emits each canonical edge by lower endpoint, then by its
        # input insertion order for that endpoint.
        adjacency: list[dict[int, int]] = [dict() for _ in range(vertex_count)]
        for u, v, weight in edges:
            adjacency[u][v] = weight
            adjacency[v][u] = weight
        source_order: list[tuple[int, int, int]] = []
        seen: set[tuple[int, int]] = set()
        for u in range(vertex_count):
            for v, weight in adjacency[u].items():
                if (u, v) not in seen:
                    seen.add((v, u))
                    source_order.append((u, v, weight))

        parent = list(range(vertex_count))
        rank = [0] * vertex_count

        def find(node: int) -> int:
            if parent[node] != node:
                parent[node] = find(parent[node])
            return parent[node]

        def union(root_u: int, root_v: int) -> None:
            if rank[root_u] > rank[root_v]:
                parent[root_v] = root_u
            else:
                parent[root_u] = root_v
                if rank[root_u] == rank[root_v]:
                    rank[root_v] += 1

        # Disconnected graphs are outside the bounded contract: the pinned
        # implementation indexes past its edge list before it can return.
        connectivity_parent = list(range(vertex_count))

        def connectivity_find(node: int) -> int:
            while connectivity_parent[node] != node:
                connectivity_parent[node] = connectivity_parent[connectivity_parent[node]]
                node = connectivity_parent[node]
            return node

        for u, v, _ in edges:
            ru, rv = connectivity_find(u), connectivity_find(v)
            if ru != rv:
                connectivity_parent[ru] = rv
        if len({connectivity_find(node) for node in range(vertex_count)}) != 1:
            return INVALID_RESULT, b""

        source_order.sort(key=lambda edge: edge[2])
        accepted = []
        for u, v, weight in source_order:
            root_u, root_v = find(u), find(v)
            if root_u != root_v:
                accepted.append((u, v, weight))
                union(root_u, root_v)
                if len(accepted) == vertex_count - 1:
                    break

    words = [len(accepted)]
    for edge in accepted:
        words.extend(edge)
    encoded = struct.pack("<" + "i" * len(words), *words)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
