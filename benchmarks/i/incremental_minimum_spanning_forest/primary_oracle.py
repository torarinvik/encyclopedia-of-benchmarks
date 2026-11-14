"""Independent bounded model of insertion-only minimum spanning forests."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 16
MAX_EDGES = 32
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_EDGES


def expected_output(values: Sequence[int] | None, capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    if len(values) < 2:
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 1 <= m <= MAX_EDGES or len(values) != 2 + 3 * m:
        return -1, b""
    edges = []
    weights = set()
    for i in range(m):
        u, v, weight = values[2 + 3 * i:5 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or not 1 <= weight <= 1_000_000 or weight in weights:
            return -1, b""
        weights.add(weight)
        edges.append((u, v, weight))

    forest: set[int] = set()
    result = []
    for index, (start, target, weight) in enumerate(edges):
        if start == target:
            result.append(index)
            continue
        adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
        for old in forest:
            u, v, _ = edges[old]
            adjacency[u].append((v, old))
            adjacency[v].append((u, old))
        parent: list[tuple[int, int] | None] = [None] * n
        parent[start] = (start, -1)
        queue = [start]
        for vertex in queue:
            for neighbor, edge in adjacency[vertex]:
                if parent[neighbor] is None:
                    parent[neighbor] = (vertex, edge)
                    queue.append(neighbor)
        if parent[target] is None:
            forest.add(index)
            result.append(-1)
            continue
        heaviest = -1
        vertex = target
        while vertex != start:
            previous, edge = parent[vertex]  # type: ignore[misc]
            if heaviest < 0 or edges[edge][2] > edges[heaviest][2]:
                heaviest = edge
            vertex = previous
        if weight < edges[heaviest][2]:
            forest.remove(heaviest)
            forest.add(index)
            result.append(heaviest)
        else:
            result.append(index)
    encoded = b"".join(struct.pack("<q", item) for item in result)
    if output_is_null or capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
