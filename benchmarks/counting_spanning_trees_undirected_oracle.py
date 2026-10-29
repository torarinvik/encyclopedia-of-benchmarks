"""Subset-enumeration oracle for bounded undirected spanning-tree counts."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations
import struct

MAX_VERTICES = 7
MAX_EDGES = 21
MAX_INPUT_LENGTH = 44
OUTPUT_BYTES = 8
MODULUS = 1_000_000_007


def _is_spanning_tree(vertex_count: int, edges: Sequence[tuple[int, int]], selected: tuple[int, ...]) -> bool:
    parent = list(range(vertex_count))

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    components = vertex_count
    for edge_index in selected:
        left, right = edges[edge_index]
        left_root = find(left)
        right_root = find(right)
        if left_root == right_root:
            return False
        parent[left_root] = right_root
        components -= 1
    return components == 1


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Count acyclic connected (n-1)-edge subsets, independently of determinants."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (capacity is not None and (type(capacity) is not int or capacity < 0))
        or (input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH))
        or (input_is_null and values not in (None, [], ()))
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (
        len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
        or (input_length is not None and input_length != len(values))
    ):
        return -1, b""

    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + 2 * edge_count:
        return -1, b""
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for edge_index in range(edge_count):
        left, right = values[2 + 2 * edge_index:4 + 2 * edge_index]
        if not (0 <= left < vertex_count and 0 <= right < vertex_count) or left == right:
            return -1, b""
        edge = (min(left, right), max(left, right))
        if edge in seen:
            return -1, b""
        seen.add(edge)
        edges.append((left, right))

    count = sum(
        1 for selected in combinations(range(edge_count), vertex_count - 1)
        if _is_spanning_tree(vertex_count, edges, selected)
    )
    payload = struct.pack("<Q", count % MODULUS)
    if output_is_null or (capacity is not None and capacity < OUTPUT_BYTES):
        return -2, b""
    return OUTPUT_BYTES, payload
