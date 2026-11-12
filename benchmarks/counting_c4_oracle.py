"""Edge-subset oracle for bounded per-edge undirected C4 counts."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations
import struct

MAX_VERTICES = 8
MAX_EDGES = 12
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_EDGES


def _is_four_cycle(edges: Sequence[tuple[int, int]], selected: tuple[int, ...]) -> bool:
    degree: dict[int, int] = {}
    adjacency: dict[int, list[int]] = {}
    for edge_index in selected:
        u, v = edges[edge_index]
        degree[u] = degree.get(u, 0) + 1
        degree[v] = degree.get(v, 0) + 1
        adjacency.setdefault(u, []).append(v)
        adjacency.setdefault(v, []).append(u)
    if len(degree) != 4 or any(value != 2 for value in degree.values()):
        return False
    reached = {next(iter(degree))}
    pending = list(reached)
    while pending:
        u = pending.pop()
        for v in adjacency[u]:
            if v not in reached:
                reached.add(v)
                pending.append(v)
    return len(reached) == 4


def expected_output(
        values: Sequence[int] | None,
        capacity: int | None = None,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, bytes]:
    """Enumerate edge-ID quadruples and count each cycle at all four edges."""
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
        len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
        or (input_length is not None and input_length != len(values))
    ):
        return -1, b""

    vertex_count, edge_count = values[:2]
    if not 2 <= vertex_count <= MAX_VERTICES or not 1 <= edge_count <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + 2 * edge_count:
        return -1, b""
    edges: list[tuple[int, int]] = []
    for edge_index in range(edge_count):
        u, v = values[2 + 2 * edge_index:4 + 2 * edge_index]
        if not (0 <= u < vertex_count and 0 <= v < vertex_count and u != v):
            return -1, b""
        edges.append((u, v))

    counts = [0] * edge_count
    for selected in combinations(range(edge_count), 4):
        if _is_four_cycle(edges, selected):
            for edge_index in selected:
                counts[edge_index] += 1
    payload = b"".join(struct.pack("<Q", count) for count in counts)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
