"""Network-erosion strength of connection for the bounded directed profile."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
import struct

MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1)
MAX_VALID_INPUT_LENGTH = 4 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
OUTPUT_BYTES = 16
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int]) -> tuple[int, int, int, list[list[bool]]] | None:
    if (not isinstance(values, Sequence) or len(values) < 4
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    n, edge_count, source, target = values[:4]
    if not 2 <= n <= MAX_VERTICES or not 0 <= edge_count <= n * (n - 1):
        return None
    if not 0 <= source < n or not 0 <= target < n or source == target:
        return None
    if len(values) != 4 + 2 * edge_count:
        return None
    adjacency = [[False] * n for _ in range(n)]
    cursor = 4
    for _ in range(edge_count):
        start, end = values[cursor:cursor + 2]
        cursor += 2
        if not 0 <= start < n or not 0 <= end < n or start == end:
            return None
        if adjacency[start][end]:
            return None
        adjacency[start][end] = True
    return n, source, target, adjacency


def _shortest_path(adjacency: list[list[bool]], source: int, target: int) -> list[int] | None:
    n = len(adjacency)
    distance = [-1] * n
    predecessor = [-1] * n
    queue = [source]
    distance[source] = 0
    for vertex in queue:
        for successor in range(n):
            if adjacency[vertex][successor] and distance[successor] == -1:
                distance[successor] = distance[vertex] + 1
                predecessor[successor] = vertex
                queue.append(successor)
    if distance[target] == -1:
        return None
    path = [target]
    while path[-1] != source:
        path.append(predecessor[path[-1]])
    path.reverse()
    return path


def strength_fraction(values: Sequence[int]) -> Fraction | None:
    """Return the exact normalized score, or None for a malformed frame."""
    parsed = _parse(values)
    if parsed is None:
        return None
    n, source, target, adjacency = parsed
    distances: list[int | None] = [None] * n
    first_path = _shortest_path(adjacency, source, target)
    if first_path is not None:
        initial_length = len(first_path) - 1
        distances[source] = initial_length
        distances[target] = initial_length
        while True:
            path = _shortest_path(adjacency, source, target)
            if path is None:
                break
            path_length = len(path) - 1
            if path_length == 1:
                adjacency[source][target] = False
                continue
            for vertex in path:
                if distances[vertex] is None:
                    distances[vertex] = path_length
            for vertex in path[1:-1]:
                for neighbor in range(n):
                    adjacency[vertex][neighbor] = False
                    adjacency[neighbor][vertex] = False

    reciprocal_sum = sum(
        (Fraction(1, distance) for distance in distances if distance is not None),
        Fraction(0, 1),
    )
    return reciprocal_sum * Fraction(2, n + 2)


def expected_result(values: Sequence[int], *, input_length: int | None = None,
                    input_is_null: bool = False, output_capacity: int = OUTPUT_BYTES,
                    output_is_null: bool = False) -> int:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or (input_length is not None and type(input_length) is not int)
            or (input_length is not None and input_length < 0)
            or type(output_capacity) is not int or output_capacity < 0):
        return -1
    if input_is_null or not isinstance(values, Sequence):
        return -1
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return -1
    if input_length is not None and input_length != len(values):
        return -1
    result = strength_fraction(values)
    if result is None:
        return -1
    if output_is_null or output_capacity < OUTPUT_BYTES:
        return -2
    return OUTPUT_BYTES


def expected_output(values: Sequence[int], *, input_length: int | None = None,
                    input_is_null: bool = False, output_capacity: int = OUTPUT_BYTES,
                    output_is_null: bool = False) -> bytes:
    if expected_result(values, input_length=input_length, input_is_null=input_is_null,
                       output_capacity=output_capacity, output_is_null=output_is_null) != OUTPUT_BYTES:
        return b""
    result = strength_fraction(values)
    assert result is not None
    return struct.pack("<qq", result.numerator, result.denominator)
