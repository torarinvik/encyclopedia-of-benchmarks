"""Independent combination-enumeration verifier for GBBS 4-clique count."""

from __future__ import annotations

import struct

MAX_NODES = 24
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
OUTPUT_BYTES = 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
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
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(item) is not int or not I64_MIN <= item <= I64_MAX
                   for item in values)):
        return INVALID_RESULT, b""

    n, edge_count = values[:2]
    if (not 1 <= n <= MAX_NODES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count):
        return INVALID_RESULT, b""
    adjacency = [[False] * n for _ in range(n)]
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left < right < n or adjacency[left][right]:
            return INVALID_RESULT, b""
        adjacency[left][right] = adjacency[right][left] = True

    # Enumerate each unordered 4-set exactly once, independently of the
    # source-inspired oriented-neighborhood intersection used by the package
    # oracle and the language ports.
    total = 0
    for a in range(n):
        for b in range(a + 1, n):
            if not adjacency[a][b]:
                continue
            for c in range(b + 1, n):
                if not (adjacency[a][c] and adjacency[b][c]):
                    continue
                for d in range(c + 1, n):
                    if adjacency[a][d] and adjacency[b][d] and adjacency[c][d]:
                        total += 1
    encoded = struct.pack("<q", total)
    if output_is_null or capacity is not None and capacity < OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, encoded
