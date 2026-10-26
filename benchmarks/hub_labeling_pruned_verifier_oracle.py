"""Canonical shortest-path-pair verifier for pruned hub labels."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_INPUT = 2 + MAX_VERTICES + 2 * MAX_EDGES


def _read_graph(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + n + 2 * m:
        return None
    order = list(values[2:2 + n])
    if len(set(order)) != n or any(vertex < 0 or vertex >= n for vertex in order):
        return None
    graph = [[] for _ in range(n)]
    previous = (-1, -1)
    for index in range(m):
        u, v = values[2 + n + 2 * index:4 + n + 2 * index]
        if not 0 <= u < v < n or (u, v) <= previous:
            return None
        previous = u, v
        graph[u].append(v)
        graph[v].append(u)
    reached = {0}
    pending = [0]
    for vertex in pending:
        for neighbor in graph[vertex]:
            if neighbor not in reached:
                reached.add(neighbor)
                pending.append(neighbor)
    if len(reached) != n:
        return None
    for source in range(n):
        distance = [-1] * n
        paths = [0] * n
        distance[source] = 0
        paths[source] = 1
        pending = [source]
        for vertex in pending:
            for neighbor in graph[vertex]:
                if distance[neighbor] < 0:
                    distance[neighbor] = distance[vertex] + 1
                    paths[neighbor] = paths[vertex]
                    pending.append(neighbor)
                elif distance[neighbor] == distance[vertex] + 1:
                    paths[neighbor] = min(2, paths[neighbor] + paths[vertex])
        if any(count != 1 for count in paths):
            return None
    return n, order, graph


def _canonical(n: int, order: list[int], graph: list[list[int]]) -> list[list[int]]:
    distances = [[-1] * n for _ in range(n)]
    for source in range(n):
        distances[source][source] = 0
        pending = [source]
        for vertex in pending:
            for neighbor in graph[vertex]:
                if distances[source][neighbor] < 0:
                    distances[source][neighbor] = distances[source][vertex] + 1
                    pending.append(neighbor)
    labels = [[-1] * n for _ in range(n)]
    for left in range(n):
        for right in range(left, n):
            distance = distances[left][right]
            hub = next(vertex for vertex in order
                       if distances[left][vertex] + distances[vertex][right] == distance)
            labels[left][hub] = distances[left][hub]
            labels[right][hub] = distances[right][hub]
    return labels


def _encode(labels: list[list[int]]) -> bytes:
    fields = [len(labels)]
    for row in labels:
        present = [hub for hub, distance in enumerate(row) if distance >= 0]
        fields.append(len(present))
        for hub in present:
            fields.append(hub | (row[hub] << 8))
    return b"".join(struct.pack("<q", value) for value in fields)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _read_graph(values)
    if parsed is None:
        return -1, b""
    n, order, graph = parsed
    payload = _encode(_canonical(n, order, graph))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
