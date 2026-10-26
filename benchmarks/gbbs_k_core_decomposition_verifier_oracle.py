"""Threshold-peeling verifier for the bounded GBBS k-core profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 128
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (values is not None and (not isinstance(values, (list, tuple))
                                or len(values) > MAX_INPUT_LENGTH
                                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                                       for value in values))
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return INVALID_RESULT, b""
    if input_is_null or values is None or len(values) < 2:
        return INVALID_RESULT, b""
    node_count, edge_count = values[:2]
    if (not 1 <= node_count <= MAX_NODES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count):
        return INVALID_RESULT, b""
    adjacency = [[False] * node_count for _ in range(node_count)]
    for offset in range(2, len(values), 2):
        left, right = values[offset : offset + 2]
        if not 0 <= left < right < node_count or adjacency[left][right]:
            return INVALID_RESULT, b""
        adjacency[left][right] = adjacency[right][left] = True

    core = [0] * node_count
    for threshold in range(1, node_count):
        alive = [True] * node_count
        while True:
            removed = [
                vertex for vertex in range(node_count)
                if alive[vertex]
                and sum(alive[neighbor] and adjacency[vertex][neighbor]
                        for neighbor in range(node_count)) < threshold
            ]
            if not removed:
                break
            for vertex in removed:
                alive[vertex] = False
        for vertex in range(node_count):
            if alive[vertex]:
                core[vertex] = threshold

    output = b"".join(struct.pack("<q", value) for value in core)
    if output_is_null or capacity is not None and capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
