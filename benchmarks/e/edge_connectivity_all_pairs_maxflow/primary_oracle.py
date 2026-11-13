"""Edge connectivity by all-pairs unit-capacity max flow."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 10
MAX_EDGES = 45
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE_BASIS = [
    {
        "organization": "CP-Algorithms",
        "title": "Edge connectivity / Vertex connectivity",
        "url": "https://cp-algorithms.com/graph/edge_vertex_connectivity.html",
        "role": "all_terminal_pairs_unit_capacity_max_flow_description",
        "license": "CC BY-SA 4.0",
    }
]


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (
        type(input_length) is not int
        or input_length != len(values)
        or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    vertex_count, edge_count = values[0], values[1]
    if not 2 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for edge_index in range(edge_count):
        left = values[2 + 2 * edge_index]
        right = values[3 + 2 * edge_index]
        if not (0 <= left < vertex_count and 0 <= right < vertex_count) or left == right:
            return None
        edge = (left, right) if left < right else (right, left)
        if edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return vertex_count, edges


def _max_flow(
    vertex_count: int,
    edges: list[tuple[int, int]],
    source: int,
    sink: int,
    limit: int,
) -> int:
    residual = [[0] * vertex_count for _ in range(vertex_count)]
    for left, right in edges:
        residual[left][right] = 1
        residual[right][left] = 1

    flow = 0
    while flow < limit:
        parent = [-1] * vertex_count
        parent[source] = source
        queue = [source]
        head = 0
        while head < len(queue) and parent[sink] == -1:
            current = queue[head]
            head += 1
            for neighbor in range(vertex_count):
                if residual[current][neighbor] > 0 and parent[neighbor] == -1:
                    parent[neighbor] = current
                    queue.append(neighbor)
                    if neighbor == sink:
                        break
        if parent[sink] == -1:
            break

        amount = limit - flow
        current = sink
        while current != source:
            previous = parent[current]
            amount = min(amount, residual[previous][current])
            current = previous
        current = sink
        while current != source:
            previous = parent[current]
            residual[previous][current] -= amount
            residual[current][previous] += amount
            current = previous
        flow += amount
    return flow


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the least unit-capacity s-t maximum flow over all vertex pairs."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertex_count, edges = parsed
    best = vertex_count - 1
    for source in range(vertex_count):
        for sink in range(source + 1, vertex_count):
            flow = _max_flow(vertex_count, edges, source, sink, best)
            if flow < best:
                best = flow
            if best == 0:
                return 0
    return best
