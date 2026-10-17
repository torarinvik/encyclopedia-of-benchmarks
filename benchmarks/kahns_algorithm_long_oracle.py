"""Independent bounded oracle for longest DAG path length in vertices."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_VERTICES = 32
MAX_EDGES = 128
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
) -> int:
    """Return the longest DAG path size or -1 for malformed or cyclic input."""
    if values is None:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return INVALID_RESULT
    if len(values) != 2 + 2 * edge_count:
        return INVALID_RESULT

    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    for index in range(edge_count):
        source, destination = values[2 + 2 * index:4 + 2 * index]
        if not (0 <= source < vertex_count and 0 <= destination < vertex_count):
            return INVALID_RESULT
        adjacency[source].append(destination)

    state = [0] * vertex_count
    longest = [0] * vertex_count

    def visit(vertex: int) -> int:
        if state[vertex] == 1:
            return 0
        if state[vertex] == 2:
            return longest[vertex]
        state[vertex] = 1
        distance = 1
        for neighbor in adjacency[vertex]:
            following = visit(neighbor)
            if following == 0:
                return 0
            distance = max(distance, following + 1)
        state[vertex] = 2
        longest[vertex] = distance
        return distance

    result = 0
    for vertex in range(vertex_count):
        distance = visit(vertex)
        if distance == 0:
            return INVALID_RESULT
        result = max(result, distance)
    return result
