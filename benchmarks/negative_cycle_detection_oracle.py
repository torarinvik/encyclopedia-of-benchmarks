"""Source-order oracle for the bounded negative-cycle witness profile."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_NODES = 20
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (MAX_NODES + 2)
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[:2]
    if not 0 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 3 * m:
        return None
    edges = []
    for pos in range(2, len(values), 3):
        u, v, weight = values[pos:pos + 3]
        if not 0 <= u < n or not 0 <= v < n or not -1000 <= weight <= 1000:
            return None
        edges.append((u, v, weight))
    return n, edges


def _source_order_record(n: int, edges: list[tuple[int, int, int]]) -> list[int]:
    # All-zero initial distances model a zero-weight super-source connected to
    # every vertex. Input-order in-place relaxation fixes the witness choice.
    distance = [0] * n
    predecessor = [-1] * n
    changed_vertex = -1
    for _pass in range(n):
        changed_vertex = -1
        for u, v, weight in edges:
            candidate = distance[u] + weight
            if candidate < distance[v]:
                distance[v] = candidate
                predecessor[v] = u
                changed_vertex = v
        if changed_vertex < 0:
            break
    if changed_vertex < 0:
        return [0]

    vertex = changed_vertex
    for _ in range(n):
        if predecessor[vertex] < 0:
            return [0]
        vertex = predecessor[vertex]
    start = vertex
    backwards = []
    while len(backwards) < n and predecessor[vertex] >= 0:
        backwards.append(vertex)
        vertex = predecessor[vertex]
        if vertex == start:
            break
    if vertex != start or not backwards:
        return [0]
    cycle = list(reversed(backwards))
    minimum = min(range(len(cycle)), key=cycle.__getitem__)
    cycle = cycle[minimum:] + cycle[:minimum]
    return [1, len(cycle), *cycle]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    n, edges = parsed
    record = _source_order_record(n, edges)
    output = b"".join(struct.pack("<q", value) for value in record)
    if output_is_null or capacity is not None and capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
