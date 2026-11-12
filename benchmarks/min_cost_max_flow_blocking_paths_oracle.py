"""Primary tight-residual blocking-flow oracle for the bounded MCMF profile."""
from __future__ import annotations

from collections import deque
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
    adjacency: list[list[int]] = [[] for _ in range(n)]
    for index in range(m):
        u, v, capacity, cost = values[5 + 4 * index:9 + 4 * index]
        if not (0 <= u < n and 0 <= v < n and 0 <= capacity <= 5 and 0 <= cost <= 20):
            return INVALID_RESULT, b""
        forward = len(edges)
        reverse = forward + 1
        edges.append([u, v, capacity, cost, reverse])
        edges.append([v, u, 0, -cost, forward])
        adjacency[u].append(forward)
        adjacency[v].append(reverse)

    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return OUTPUT_ERROR, b""

    total_flow = 0
    total_cost = 0
    while total_flow < flow_limit:
        distance = [INF] * n
        distance[source] = 0
        pending = deque([source])
        queued = [False] * n
        queued[source] = True
        while pending:
            u = pending.popleft()
            queued[u] = False
            for edge_index in adjacency[u]:
                _, v, remaining, cost, _ = edges[edge_index]
                candidate = distance[u] + cost
                if remaining > 0 and candidate < distance[v]:
                    distance[v] = candidate
                    if not queued[v]:
                        pending.append(v)
                        queued[v] = True
        if distance[sink] == INF:
            break

        while total_flow < flow_limit:
            level = [-1] * n
            level[source] = 0
            pending_vertices = deque([source])
            while pending_vertices:
                u = pending_vertices.popleft()
                for edge_index in adjacency[u]:
                    _, v, remaining, cost, _ = edges[edge_index]
                    if (remaining > 0 and level[v] < 0
                            and distance[v] == distance[u] + cost):
                        level[v] = level[u] + 1
                        pending_vertices.append(v)
            if level[sink] < 0:
                break

            current = [0] * n

            def send(u: int, amount: int) -> int:
                if u == sink:
                    return amount
                while current[u] < len(adjacency[u]):
                    edge_index = adjacency[u][current[u]]
                    _, v, remaining, cost, reverse = edges[edge_index]
                    if (remaining <= 0 or distance[v] != distance[u] + cost
                            or level[v] != level[u] + 1):
                        current[u] += 1
                        continue
                    pushed = send(v, min(amount, remaining))
                    if pushed > 0:
                        edges[edge_index][2] -= pushed
                        edges[reverse][2] += pushed
                        if edges[edge_index][2] == 0:
                            current[u] += 1
                        return pushed
                    current[u] += 1
                return 0

            while total_flow < flow_limit:
                amount = send(source, flow_limit - total_flow)
                if amount == 0:
                    break
                total_flow += amount
                total_cost += amount * distance[sink]

    return OUTPUT_BYTES, struct.pack("<qq", total_flow, total_cost)
