"""Independent greedy-order and distance-matrix verifier for GOC-MCDS-C."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 17)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if (input_is_null or not isinstance(values, (list, tuple)) or not 3 <= len(values) <= 17
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 8 or len(values) != 1 + 2 * n:
        return -1, b""
    full = (1 << n) - 1
    adjacency = values[1:1 + n]
    ids = values[1 + n:]
    if any(mask < 0 or mask & ~full or mask & (1 << vertex)
           for vertex, mask in enumerate(adjacency)):
        return -1, b""
    if (any(not 1 <= node_id <= 1000 for node_id in ids)
            or len(set(ids)) != n):
        return -1, b""
    for u in range(n):
        for v in range(n):
            if bool(adjacency[u] & (1 << v)) != bool(adjacency[v] & (1 << u)):
                return -1, b""

    distance = [[n + 1] * n for _ in range(n)]
    for u in range(n):
        distance[u][u] = 0
        for v in range(n):
            if adjacency[u] & (1 << v):
                distance[u][v] = 1
    for middle in range(n):
        for source in range(n):
            for target in range(n):
                distance[source][target] = min(
                    distance[source][target],
                    distance[source][middle] + distance[middle][target])
    if any(distance[0][vertex] > n for vertex in range(n)):
        return -1

    independent = 0
    for vertex in sorted(range(n), key=lambda item: ids[item]):
        if not any(independent & (1 << other) and adjacency[vertex] & (1 << other)
                   for other in range(n)):
            independent |= 1 << vertex

    connectors = 0
    selected = sorted((vertex for vertex in range(n) if independent & (1 << vertex)),
                      key=lambda item: ids[item])
    for position, source in enumerate(selected):
        for target in selected[position + 1:]:
            length = distance[source][target]
            if length <= 3:
                current = source
                remaining = length
                while remaining > 1:
                    next_vertex = min(
                        (vertex for vertex in range(n)
                         if adjacency[current] & (1 << vertex)
                         and distance[vertex][target] == remaining - 1),
                        key=lambda item: ids[item])
                    connectors |= 1 << next_vertex
                    current = next_vertex
                    remaining -= 1
    payload = struct.pack("<qq", independent, independent | connectors)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
