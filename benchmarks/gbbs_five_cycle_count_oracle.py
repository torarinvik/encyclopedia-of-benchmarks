"""Bounded exact oracle for GBBS's undirected five-cycle count."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(item) is not int or not I64_MIN <= item <= I64_MAX
                   for item in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    adjacency = [[False] * n for _ in range(n)]
    for position in range(2, len(values), 2):
        u, v = values[position:position + 2]
        if not 0 <= u < v < n or adjacency[u][v]:
            return None
        adjacency[u][v] = adjacency[v][u] = True
    return n, adjacency


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    n, adjacency = parsed

    count = 0
    for vertices in itertools.combinations(range(n), 5):
        start = vertices[0]
        remainder = vertices[1:]
        for path_order in itertools.permutations(remainder):
            if path_order[0] >= path_order[-1]:
                continue
            cycle = (start, *path_order)
            if all(adjacency[cycle[index]][cycle[(index + 1) % 5]]
                   for index in range(5)):
                count += 1
    encoded = struct.pack("<q", count)
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, encoded
