"""Pruned-labeling oracle for a bounded undirected unweighted graph."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_INPUT = 2 + MAX_VERTICES + 2 * MAX_EDGES
MAX_OUTPUT_FIELDS = 1 + MAX_VERTICES * (1 + MAX_VERTICES)
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_FIELDS


def _parse(values: Sequence[int] | None) -> tuple[int, list[int], list[tuple[int, int]], list[list[bool]]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if len(values) != 2 + n + 2 * m:
        return None
    order = list(values[2:2 + n])
    if sorted(order) != list(range(n)):
        return None
    edges: list[tuple[int, int]] = []
    adjacency = [[False] * n for _ in range(n)]
    offset = 2 + n
    previous = (-1, -1)
    for index in range(m):
        left, right = values[offset + 2 * index:offset + 2 * index + 2]
        if not 0 <= left < right < n or (left, right) <= previous:
            return None
        previous = left, right
        edges.append((left, right))
        adjacency[left][right] = adjacency[right][left] = True
    seen = {0}
    queue = [0]
    for vertex in queue:
        for neighbor in range(n):
            if adjacency[vertex][neighbor] and neighbor not in seen:
                seen.add(neighbor)
                queue.append(neighbor)
    if len(seen) != n:
        return None
    for source in range(n):
        distance = [-1] * n
        ways = [0] * n
        distance[source] = 0
        ways[source] = 1
        queue = [source]
        for vertex in queue:
            for neighbor in range(n):
                if not adjacency[vertex][neighbor]:
                    continue
                if distance[neighbor] < 0:
                    distance[neighbor] = distance[vertex] + 1
                    ways[neighbor] = ways[vertex]
                    queue.append(neighbor)
                elif distance[neighbor] == distance[vertex] + 1:
                    ways[neighbor] = min(2, ways[neighbor] + ways[vertex])
        if any(count != 1 for count in ways):
            return None
    return n, order, edges, adjacency


def _label(n: int, order: list[int], adjacency: list[list[bool]]) -> list[list[int]]:
    labels = [[-1] * n for _ in range(n)]
    for hub in order:
        distance = [-1] * n
        distance[hub] = 0
        queue = [hub]
        head = 0
        while head < len(queue):
            vertex = queue[head]
            head += 1
            estimate = min((labels[hub][common] + labels[vertex][common]
                            for common in range(n)
                            if labels[hub][common] >= 0 and labels[vertex][common] >= 0),
                           default=MAX_VERTICES * 2)
            if estimate <= distance[vertex]:
                continue
            labels[vertex][hub] = distance[vertex]
            for neighbor in range(n):
                if adjacency[vertex][neighbor] and distance[neighbor] < 0:
                    distance[neighbor] = distance[vertex] + 1
                    queue.append(neighbor)
    return labels


def _encode(labels: list[list[int]]) -> bytes:
    fields = [len(labels)]
    for row in labels:
        present = [hub for hub, distance in enumerate(row) if distance >= 0]
        fields.append(len(present))
        for hub in present:
            fields.append(hub | (row[hub] << 8))
    return b"".join(struct.pack("<q", field) for field in fields)


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, order, _edges, adjacency = parsed
    payload = _encode(_label(n, order, adjacency))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
