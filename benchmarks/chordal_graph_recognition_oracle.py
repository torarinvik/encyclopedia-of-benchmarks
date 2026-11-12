"""Reference oracle for bounded MCS chordal-graph recognition."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 6
MAX_EDGES = 15
MAX_INPUT = 32
MAX_OUTPUT_VALUES = 8
MAX_OUTPUT_BYTES = 64


def _pack(words: list[int]) -> bytes:
    return b"".join(struct.pack("<Q", word) for word in words)


def _induced_cycle(adjacent: list[list[bool]]) -> list[int] | None:
    n = len(adjacent)
    for mask in range(1 << n):
        vertices = [v for v in range(n) if mask & (1 << v)]
        if len(vertices) < 4:
            continue
        if any(sum(adjacent[v][u] for u in vertices) != 2 for v in vertices):
            continue
        seen = {vertices[0]}
        queue = [vertices[0]]
        for v in queue:
            for u in vertices:
                if adjacent[v][u] and u not in seen:
                    seen.add(u)
                    queue.append(u)
        if len(seen) != len(vertices):
            continue
        start = vertices[0]
        next_vertex = min(u for u in vertices if adjacent[start][u])
        cycle = [start]
        previous = start
        current = next_vertex
        while current != start:
            cycle.append(current)
            following = [u for u in vertices if adjacent[current][u] and u != previous]
            previous, current = current, following[0]
        return cycle
    return None


def _mcs_order(adjacent: list[list[bool]]) -> list[int]:
    n = len(adjacent)
    selected = [False] * n
    label = [0] * n
    reverse_order: list[int] = []
    for _ in range(n):
        vertex = min((v for v in range(n) if not selected[v]),
                     key=lambda v: (-label[v], v))
        selected[vertex] = True
        reverse_order.append(vertex)
        for other in range(n):
            if not selected[other] and adjacent[vertex][other]:
                label[other] += 1
    return list(reversed(reverse_order))


def _is_peo(adjacent: list[list[bool]], order: list[int]) -> bool:
    position = [0] * len(order)
    for i, vertex in enumerate(order):
        position[vertex] = i
    for vertex in order:
        later = [u for u in range(len(order))
                 if adjacent[vertex][u] and position[u] > position[vertex]]
        if later:
            parent = min(later, key=position.__getitem__)
            if any(u != parent and not adjacent[parent][u] for u in later):
                return False
    return True


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))
            or len(values) < 2 or len(values) > MAX_INPUT
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= min(MAX_EDGES, n * (n - 1) // 2):
        return -1, b""
    if len(values) != 2 + 2 * m:
        return -1, b""
    adjacent = [[False] * n for _ in range(n)]
    for edge in range(m):
        left, right = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= left < n or not 0 <= right < n or left == right or adjacent[left][right]:
            return -1, b""
        adjacent[left][right] = adjacent[right][left] = True

    order = _mcs_order(adjacent)
    if _is_peo(adjacent, order):
        payload = _pack([1, *order])
    else:
        cycle = _induced_cycle(adjacent)
        if cycle is None:
            return -1, b""
        payload = _pack([0, len(cycle), *cycle])
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
