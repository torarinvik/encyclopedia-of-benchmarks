"""Leaf-layer peeling reference for a bounded tree-center workload."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 2 * (MAX_N - 1)
MAX_OUTPUT_BYTES = 16


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    size = len(values) if input_length is None else input_length
    if (type(size) is not int or size != len(values)
            or not 1 <= size <= MAX_INPUT_LENGTH):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or size != 1 + 2 * (n - 1):
        return None
    adjacency = [[] for _ in range(n)]
    degree = [0] * n
    parent = list(range(n))
    component_size = [1] * n

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for offset in range(1, size, 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < n or not 0 <= right < n or left == right:
            return None
        root_left, root_right = find(left), find(right)
        if root_left == root_right:
            return None
        if component_size[root_left] < component_size[root_right]:
            root_left, root_right = root_right, root_left
        parent[root_right] = root_left
        component_size[root_left] += component_size[root_right]
        adjacency[left].append(right)
        adjacency[right].append(left)
        degree[left] += 1
        degree[right] += 1
    if n > 1 and component_size[find(0)] != n:
        return None
    return adjacency, degree


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return result bytes for `[N,(u,v)...]`."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    adjacency, degree = parsed
    n = len(adjacency)
    active = [True] * n
    leaves = [vertex for vertex in range(n) if degree[vertex] <= 1]
    remaining = n
    while remaining > 2:
        for leaf in leaves:
            active[leaf] = False
        remaining -= len(leaves)
        for leaf in leaves:
            for neighbor in adjacency[leaf]:
                if active[neighbor]:
                    degree[neighbor] -= 1
        if remaining <= 2:
            break
        leaves = [vertex for vertex in range(n)
                  if active[vertex] and degree[vertex] == 1]
    centers = [vertex for vertex in range(n) if active[vertex]]
    encoded = b"".join(struct.pack("<q", center) for center in centers)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
