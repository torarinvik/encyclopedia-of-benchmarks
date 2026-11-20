"""Exhaustive simple-path reference for network-erosion strength of connection."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
import struct

OUTPUT_BYTES = 16
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _read_graph(values: Sequence[int]) -> tuple[int, int, int, set[tuple[int, int]]] | None:
    if (not isinstance(values, Sequence) or len(values) < 4 or len(values) > 117
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    n, m, source, target = values[:4]
    if not 2 <= n <= 8 or not 0 <= m <= n * (n - 1):
        return None
    if not 0 <= source < n or not 0 <= target < n or source == target:
        return None
    if len(values) != 4 + 2 * m:
        return None
    edges: set[tuple[int, int]] = set()
    for offset in range(4, len(values), 2):
        edge = (values[offset], values[offset + 1])
        if (edge[0] < 0 or edge[0] >= n or edge[1] < 0 or edge[1] >= n
                or edge[0] == edge[1] or edge in edges):
            return None
        edges.add(edge)
    return n, source, target, edges


def _lexicographic_shortest_path(edges: set[tuple[int, int]], n: int,
                                 source: int, target: int) -> tuple[int, ...] | None:
    candidates: list[tuple[int, ...]] = []

    def extend(path: tuple[int, ...]) -> None:
        vertex = path[-1]
        if vertex == target:
            candidates.append(path)
            return
        for successor in range(n):
            if (vertex, successor) in edges and successor not in path:
                extend(path + (successor,))

    extend((source,))
    if not candidates:
        return None
    return min(candidates, key=lambda path: (len(path), path))


def strength_fraction(values: Sequence[int]) -> Fraction | None:
    parsed = _read_graph(values)
    if parsed is None:
        return None
    n, source, target, edges = parsed
    distances: list[int | None] = [None] * n
    initial = _lexicographic_shortest_path(edges, n, source, target)
    if initial is not None:
        initial_length = len(initial) - 1
        distances[source] = initial_length
        distances[target] = initial_length
        while True:
            path = _lexicographic_shortest_path(edges, n, source, target)
            if path is None:
                break
            path_length = len(path) - 1
            if path_length == 1:
                edges.remove((source, target))
                continue
            for vertex in path:
                if distances[vertex] is None:
                    distances[vertex] = path_length
            removed = set(path[1:-1])
            edges = {(start, end) for start, end in edges
                     if start not in removed and end not in removed}
    reciprocal_sum = Fraction(0, 1)
    for distance in distances:
        if distance is not None:
            reciprocal_sum += Fraction(1, distance)
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
