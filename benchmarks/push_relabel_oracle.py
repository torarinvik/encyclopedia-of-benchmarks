"""Independent Edmonds–Karp oracle for the bounded Push–Relabel benchmark."""

from __future__ import annotations

MAX_VERTICES = 14
MAX_CAPACITY = 1_000_000
MAX_INPUT_LENGTH = 3 + 2 * MAX_VERTICES + MAX_VERTICES * MAX_VERTICES
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def _decode(values: list[int]) -> tuple[int, list[int], list[int], list[int]] | None:
    if (not isinstance(values, list) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return None

    vertex_count = values[0]
    source_count = values[1]
    if not 2 <= vertex_count <= MAX_VERTICES or not 1 <= source_count < vertex_count:
        return None
    sink_count_index = 2 + source_count
    if sink_count_index >= len(values):
        return None
    source_nodes = values[2:sink_count_index]
    sink_count = values[sink_count_index]
    if not 1 <= sink_count <= vertex_count - source_count:
        return None
    matrix_start = sink_count_index + 1 + sink_count
    if len(values) != matrix_start + vertex_count * vertex_count:
        return None
    sink_nodes = values[sink_count_index + 1:matrix_start]
    if (len(set(source_nodes)) != source_count or len(set(sink_nodes)) != sink_count
            or set(source_nodes) & set(sink_nodes)
            or any(not 0 <= node < vertex_count for node in source_nodes + sink_nodes)):
        return None

    matrix = values[matrix_start:]
    for row in range(vertex_count):
        for column in range(vertex_count):
            capacity = matrix[row * vertex_count + column]
            if not 0 <= capacity <= MAX_CAPACITY or (row == column and capacity != 0):
                return None
    return vertex_count, source_nodes, sink_nodes, matrix


def expected_result(values: list[int]) -> int:
    """Return the maximum flow for `[n, source_count, sources..., sink_count, sinks..., matrix...]`."""
    decoded = _decode(values)
    if decoded is None:
        return -1
    vertex_count, source_nodes, sink_nodes, matrix = decoded
    terminal_count = vertex_count + 2
    super_source = vertex_count
    super_sink = vertex_count + 1
    residual = [0] * (terminal_count * terminal_count)
    for row in range(vertex_count):
        for column in range(vertex_count):
            residual[row * terminal_count + column] = matrix[row * vertex_count + column]

    flow_limit = sum(matrix[node * vertex_count + column]
                     for node in source_nodes for column in range(vertex_count))
    for node in source_nodes:
        residual[super_source * terminal_count + node] += flow_limit
    for node in sink_nodes:
        residual[node * terminal_count + super_sink] += flow_limit

    total_flow = 0
    while True:
        parent = [-1] * terminal_count
        parent[super_source] = super_source
        queue = [super_source]
        head = 0
        while head < len(queue) and parent[super_sink] == -1:
            node = queue[head]
            head += 1
            for neighbor in range(terminal_count):
                if (residual[node * terminal_count + neighbor] > 0
                        and parent[neighbor] == -1):
                    parent[neighbor] = node
                    if neighbor == super_sink:
                        break
                    queue.append(neighbor)
        if parent[super_sink] == -1:
            return total_flow

        path_flow = flow_limit
        node = super_sink
        while node != super_source:
            previous = parent[node]
            path_flow = min(path_flow, residual[previous * terminal_count + node])
            node = previous
        node = super_sink
        while node != super_source:
            previous = parent[node]
            residual[previous * terminal_count + node] -= path_flow
            residual[node * terminal_count + previous] += path_flow
            node = previous
        total_flow += path_flow
