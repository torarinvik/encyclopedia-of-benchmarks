"""Independent all-pairs verifier for negative-cycle witness output."""

from __future__ import annotations

import struct

MAX_NODES = 20
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[:2]
    if not 0 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 3*m:
        return None
    edges = []
    for pos in range(2, len(values), 3):
        u, v, weight = values[pos:pos+3]
        if not 0 <= u < n or not 0 <= v < n or not -1000 <= weight <= 1000:
            return None
        edges.append((u, v, weight))
    return n, edges


def _has_negative_cycle(n: int, edges: list[tuple[int, int, int]]) -> bool:
    # Floyd-Warshall with a zero diagonal tests every connected component and
    # does not share the primary oracle's relaxation/predecessor recurrence.
    distance: list[list[int | None]] = [[None] * n for _ in range(n)]
    for vertex in range(n):
        distance[vertex][vertex] = 0
    for u, v, weight in edges:
        old = distance[u][v]
        if old is None or weight < old:
            distance[u][v] = weight
    for middle in range(n):
        for source in range(n):
            first = distance[source][middle]
            if first is None:
                continue
            for target in range(n):
                second = distance[middle][target]
                if second is None:
                    continue
                candidate = first + second
                old = distance[source][target]
                if old is None or candidate < old:
                    distance[source][target] = candidate
    return any(distance[v][v] is not None and distance[v][v] < 0 for v in range(n))


def verify_output(values, result: int, output: bytes,
                  input_is_null: bool = False) -> bool:
    if input_is_null or values is None:
        return result == -1 and output == b""
    parsed = _parse(values)
    if parsed is None:
        return result == -1 and output == b""
    n, edges = parsed
    if len(output) != result or result < 8 or result % 8:
        return False
    fields = list(struct.unpack("<" + "q" * (result // 8), output))
    has_cycle = _has_negative_cycle(n, edges)
    if not has_cycle:
        return fields == [0]
    if len(fields) < 3 or fields[0] != 1:
        return False
    cycle_length = fields[1]
    cycle = fields[2:]
    if cycle_length != len(cycle) or not 1 <= cycle_length <= n:
        return False
    if any(type(vertex) is not int or not 0 <= vertex < n for vertex in cycle):
        return False
    if len(set(cycle)) != cycle_length or cycle[0] != min(cycle):
        return False
    total = 0
    for index, source in enumerate(cycle):
        target = cycle[(index + 1) % cycle_length]
        weights = [weight for u, v, weight in edges if u == source and v == target]
        if not weights:
            return False
        total += min(weights)
    return total < 0
