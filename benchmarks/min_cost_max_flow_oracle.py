"""Independent Bellman-Ford oracle for bounded minimum-cost maximum flow."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_VERTICES = 2
MAX_VERTICES = 8
MAX_EDGES = 16
MAX_FLOW_LIMIT = 16
MAX_INPUT_LENGTH = 5 + 4 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
OUTPUT_BYTES = 16
MAX_OUTPUT_BYTES = OUTPUT_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
INF = 1 << 60


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 5 or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""

    n, m, source, sink, flow_limit = values[:5]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return INVALID_RESULT, b""
    if len(values) != 5 + 4 * m:
        return INVALID_RESULT, b""
    if not (0 <= source < n and 0 <= sink < n and source != sink):
        return INVALID_RESULT, b""
    if not 0 <= flow_limit <= MAX_FLOW_LIMIT:
        return INVALID_RESULT, b""

    edges: list[list[int]] = []
    for index in range(m):
        u, v, capacity, cost = values[5 + 4 * index:9 + 4 * index]
        if not (0 <= u < n and 0 <= v < n and 0 <= capacity <= 5 and 0 <= cost <= 20):
            return INVALID_RESULT, b""
        edges.append([u, v, capacity, cost])

    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return OUTPUT_ERROR, b""

    # Residual edge records are [from, to, remaining capacity, cost, reverse index].
    residual: list[list[int]] = []
    for u, v, capacity, cost in edges:
        forward = len(residual)
        reverse = forward + 1
        residual.append([u, v, capacity, cost, reverse])
        residual.append([v, u, 0, -cost, forward])

    total_flow = 0
    total_cost = 0
    while total_flow < flow_limit:
        distance = [INF] * n
        parent = [-1] * n
        distance[source] = 0
        for _ in range(n - 1):
            changed = False
            for edge_index, edge in enumerate(residual):
                u, v, remaining, cost, _ = edge
                if remaining > 0 and distance[u] != INF and distance[u] + cost < distance[v]:
                    distance[v] = distance[u] + cost
                    parent[v] = edge_index
                    changed = True
            if not changed:
                break
        if distance[sink] == INF:
            break
        amount = flow_limit - total_flow
        vertex = sink
        while vertex != source:
            edge_index = parent[vertex]
            if edge_index < 0:
                return INVALID_RESULT, b""
            amount = min(amount, residual[edge_index][2])
            vertex = residual[edge_index][0]
        vertex = sink
        while vertex != source:
            edge_index = parent[vertex]
            edge = residual[edge_index]
            edge[2] -= amount
            residual[edge[4]][2] += amount
            vertex = edge[0]
        total_flow += amount
        total_cost += amount * distance[sink]

    return OUTPUT_BYTES, struct.pack("<qq", total_flow, total_cost)
