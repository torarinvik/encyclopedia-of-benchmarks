"""Brute-force oracle for bounded directed Eulerian circuit counts."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_VERTICES = 7
MAX_EDGES = 9
MAX_INPUT_LENGTH = 20
OUTPUT_BYTES = 8
MODULUS = 998_244_353


def expected_output(
        values: Sequence[int] | None,
        capacity: int | None = None,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, bytes]:
    """Enumerate edge orders with edge zero fixed as the first edge."""
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
    if not 1 <= vertex_count <= MAX_VERTICES or not 1 <= edge_count <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + 2 * edge_count:
        return -1, b""
    edges: list[tuple[int, int]] = []
    for edge_index in range(edge_count):
        source, target = values[2 + 2 * edge_index:4 + 2 * edge_index]
        if not (0 <= source < vertex_count and 0 <= target < vertex_count):
            return -1, b""
        edges.append((source, target))

    start, current = edges[0]
    used = [False] * edge_count
    used[0] = True

    def enumerate_orders(vertex: int, remaining: int) -> int:
        if remaining == 0:
            return int(vertex == start)
        count = 0
        for edge_index in range(1, edge_count):
            if not used[edge_index] and edges[edge_index][0] == vertex:
                used[edge_index] = True
                count += enumerate_orders(edges[edge_index][1], remaining - 1)
                used[edge_index] = False
        return count

    count = enumerate_orders(current, edge_count - 1) % MODULUS
    payload = struct.pack("<Q", count)
    if output_is_null or (capacity is not None and capacity < OUTPUT_BYTES):
        return -2, b""
    return OUTPUT_BYTES, payload
