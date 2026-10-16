"""Independent bounded oracle for the Edmonds–Karp maximum-flow benchmark."""

from __future__ import annotations

MAX_VERTICES = 16
MAX_CAPACITY = 1_000_000
MAX_INPUT_LENGTH = 3 + MAX_VERTICES * MAX_VERTICES
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def expected_result(values: list[int]) -> int:
    """Return max flow for [n, source, sink, row-major capacity matrix]."""
    if (not isinstance(values, list) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    vertex_count, source, sink = values[:3]
    if not 1 <= vertex_count <= MAX_VERTICES or len(values) != 3 + vertex_count * vertex_count:
        return -1
    if not 0 <= source < vertex_count or not 0 <= sink < vertex_count:
        return -1

    residual = values[3:]
    for row in range(vertex_count):
        for column in range(vertex_count):
            capacity = residual[row * vertex_count + column]
            if not 0 <= capacity <= MAX_CAPACITY or (row == column and capacity != 0):
                return -1
            if capacity and residual[column * vertex_count + row]:
                return -1
    if source == sink:
        return 0

    residual = residual.copy()
    total_flow = 0
    while True:
        parent = [-1] * vertex_count
        parent[source] = source
        queue = [source]
        head = 0
        while head < len(queue) and parent[sink] == -1:
            node = queue[head]
            head += 1
            for neighbor in range(vertex_count):
                if residual[node * vertex_count + neighbor] > 0 and parent[neighbor] == -1:
                    parent[neighbor] = node
                    if neighbor == sink:
                        break
                    queue.append(neighbor)
        if parent[sink] == -1:
            return total_flow

        path_flow = MAX_CAPACITY
        node = sink
        while node != source:
            previous = parent[node]
            path_flow = min(path_flow, residual[previous * vertex_count + node])
            node = previous
        node = sink
        while node != source:
            previous = parent[node]
            residual[previous * vertex_count + node] -= path_flow
            residual[node * vertex_count + previous] += path_flow
            node = previous
        total_flow += path_flow
