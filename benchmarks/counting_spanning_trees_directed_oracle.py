"""Edge-subset oracle for bounded outward directed spanning arborescences."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations
import struct

MAX_VERTICES = 6
MAX_EDGES = 12
MAX_INPUT_LENGTH = 27
OUTPUT_BYTES = 8
MODULUS = 998_244_353


def _is_out_arborescence(
        vertex_count: int, root: int, edges: Sequence[tuple[int, int]], selected: tuple[int, ...]) -> bool:
    indegree = [0] * vertex_count
    outgoing: list[list[int]] = [[] for _ in range(vertex_count)]
    for edge_index in selected:
        source, target = edges[edge_index]
        indegree[target] += 1
        outgoing[source].append(target)
    if indegree[root] != 0 or any(indegree[vertex] != 1 for vertex in range(vertex_count) if vertex != root):
        return False

    reached = {root}
    pending = [root]
    while pending:
        source = pending.pop()
        for target in outgoing[source]:
            if target not in reached:
                reached.add(target)
                pending.append(target)
    return len(reached) == vertex_count


def expected_output(
        values: Sequence[int] | None,
        capacity: int | None = None,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, bytes]:
    """Enumerate edge-index subsets, preserving parallel arcs as distinct choices."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (capacity is not None and (type(capacity) is not int or capacity < 0))
        or (input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH))
        or (input_is_null and values not in (None, [], ()))
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (
        len(values) < 3
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
        or (input_length is not None and input_length != len(values))
    ):
        return -1, b""

    vertex_count, edge_count, root = values[:3]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1, b""
    if not 0 <= root < vertex_count or len(values) != 3 + 2 * edge_count:
        return -1, b""
    edges: list[tuple[int, int]] = []
    for edge_index in range(edge_count):
        source, target = values[3 + 2 * edge_index:5 + 2 * edge_index]
        if not (0 <= source < vertex_count and 0 <= target < vertex_count):
            return -1, b""
        edges.append((source, target))

    count = sum(
        1 for selected in combinations(range(edge_count), vertex_count - 1)
        if _is_out_arborescence(vertex_count, root, edges, selected)
    )
    payload = struct.pack("<Q", count % MODULUS)
    if output_is_null or (capacity is not None and capacity < OUTPUT_BYTES):
        return -2, b""
    return OUTPUT_BYTES, payload
