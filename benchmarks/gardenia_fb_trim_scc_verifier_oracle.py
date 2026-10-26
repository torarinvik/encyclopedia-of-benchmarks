"""Independent transitive-closure verifier for bounded SCC outputs."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (tuple, list)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if len(values) < 2:
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + 2 * m:
        return -1, b""
    reachable = [[source == destination for destination in range(n)]
                 for source in range(n)]
    arcs = set()
    for index in range(2, len(values), 2):
        source, destination = values[index:index + 2]
        if not 0 <= source < n or not 0 <= destination < n:
            return -1, b""
        if (source, destination) in arcs:
            return -1, b""
        arcs.add((source, destination))
        reachable[source][destination] = True
    for middle in range(n):
        for source in range(n):
            if reachable[source][middle]:
                for destination in range(n):
                    reachable[source][destination] = (
                        reachable[source][destination]
                        or reachable[middle][destination])
    labels = [min(other for other in range(n)
                   if reachable[vertex][other] and reachable[other][vertex])
              for vertex in range(n)]
    output = b"".join(struct.pack("<q", value) for value in labels)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
