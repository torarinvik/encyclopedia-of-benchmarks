"""Independent oracle for the bounded Kruskal minimum-spanning-forest workload."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_VERTICES = 64
MAX_EDGES = 4096
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 24 * (MAX_VERTICES - 1)
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return (status, accepted original edge triples as little-endian i64s)."""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (tuple, list)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return -1, b""

    if (
        not isinstance(values, (tuple, list))
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or type(input_is_null) is not bool
        or (input_is_null and len(values) != 0)
        or (not input_is_null and declared_length != len(values))
        or declared_length > MAX_INPUT_LENGTH
    ):
        return -1, b""
    if input_is_null or declared_length < 2:
        return -1, b""

    vertex_count, edge_count = values[:2]
    if not 0 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + 3 * edge_count:
        return -1, b""

    edges: list[tuple[int, int, int]] = []
    for index in range(edge_count):
        offset = 2 + 3 * index
        left, right, weight = values[offset : offset + 3]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count:
            return -1, b""
        edges.append((left, right, weight))

    if type(output_is_null) is not bool:
        return -1, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null:
        return -2, b""

    # Reproduce stable weight-only scanning, but use component relabeling
    # rather than the source's disjoint-set representation.
    components = list(range(vertex_count))
    accepted: list[tuple[int, int, int]] = []
    for left, right, weight in sorted(edges, key=lambda edge: edge[2]):
        left_component = components[left]
        right_component = components[right]
        if left_component == right_component:
            continue
        accepted.append((left, right, weight))
        for vertex in range(vertex_count):
            if components[vertex] == left_component:
                components[vertex] = right_component

    flattened = [value for edge in accepted for value in edge]
    output = b"".join(struct.pack("<q", value) for value in flattened)
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
