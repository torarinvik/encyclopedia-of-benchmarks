"""Reference enumeration for TheAlgorithms/Java's directed simple cycles."""

from __future__ import annotations

MAX_VERTICES = 6
MAX_EDGES = MAX_VERTICES * MAX_VERTICES
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 2786
CYCLE_END = 255
INVALID_RESULT = -1
CAPACITY_ERROR_RESULT = -2


def expected_output(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT, b""
    vertex_count, edge_count = values[:2]
    if (not 0 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count):
        return INVALID_RESULT, b""

    adjacency = [[False] * vertex_count for _ in range(vertex_count)]
    for offset in range(2, len(values), 2):
        source, destination = values[offset:offset + 2]
        if not 0 <= source < vertex_count or not 0 <= destination < vertex_count:
            return INVALID_RESULT, b""
        adjacency[source][destination] = True

    output = bytearray()
    for start in range(vertex_count):
        path = [start]

        def visit(current: int) -> None:
            for neighbor in range(vertex_count):
                if not adjacency[current][neighbor]:
                    continue
                if neighbor == start:
                    output.extend(path)
                    output.extend((start, CYCLE_END))
                elif neighbor not in path:
                    path.append(neighbor)
                    visit(neighbor)
                    path.pop()

        visit(start)
        for vertex in range(vertex_count):
            adjacency[start][vertex] = False
            adjacency[vertex][start] = False

    if len(output) > MAX_OUTPUT_BYTES:
        raise AssertionError("MAX_OUTPUT_BYTES must cover every bounded graph")
    return len(output), bytes(output)
