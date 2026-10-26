"""Independent dense-matrix verifier for one GBBS label-propagation sweep."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
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
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return INVALID_RESULT, b""

    adjacency = [[False] * n for _ in range(n)]
    for edge_index in range(m):
        u, v = values[2 + 2 * edge_index:4 + 2 * edge_index]
        if not 0 <= u < v < n or adjacency[u][v]:
            return INVALID_RESULT, b""
        adjacency[u][v] = adjacency[v][u] = True

    labels = list(range(n))
    # Recount label frequencies from the dense matrix for each vertex and
    # update in place, so later vertices see earlier changes in this sweep.
    for node in range(n):
        frequencies = {}
        for neighbor in range(n):
            if adjacency[node][neighbor]:
                label = labels[neighbor]
                frequencies[label] = frequencies.get(label, 0) + 1
        if frequencies:
            labels[node] = max(frequencies, key=lambda label: (frequencies[label], label))

    encoded = b"".join(struct.pack("<q", label) for label in labels)
    if output_is_null or capacity is not None and capacity < len(encoded):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
