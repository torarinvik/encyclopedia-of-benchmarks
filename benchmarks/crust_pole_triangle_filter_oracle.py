"""Primary oracle for the source-specified Crust pole-adjacency filter."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 51
MAX_OUTPUT_BYTES = 392


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 3 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    sample_count, pole_count, facet_count = values[:3]
    total_vertices = sample_count + pole_count
    if not 3 <= sample_count <= 8 or not 1 <= pole_count <= 4 or total_vertices > 12 or not 0 <= facet_count <= 16:
        return -1, b""
    if len(values) != 3 + 3 * facet_count:
        return -1, b""
    kept: set[tuple[int, int, int]] = set()
    for i in range(facet_count):
        triangle = tuple(values[3 + 3 * i:6 + 3 * i])
        if any(not 0 <= vertex < total_vertices for vertex in triangle) or len(set(triangle)) != 3:
            return -1, b""
        if all(vertex < sample_count for vertex in triangle):
            kept.add(tuple(sorted(triangle)))
    ordered = sorted(kept)
    words = [len(ordered), *(vertex for triangle in ordered for vertex in triangle)]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
