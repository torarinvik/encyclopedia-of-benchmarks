"""Primary bounded trace oracle for the GOC-MCDS-C construction."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_BYTES = 16


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return None
    full = (1 << n) - 1
    adjacency = list(values[1:1 + n])
    ids = list(values[1 + n:])
    if any(mask < 0 or mask & ~full or mask & (1 << vertex)
           for vertex, mask in enumerate(adjacency)):
        return None
    if any(not 1 <= node_id <= 1000 for node_id in ids) or len(set(ids)) != n:
        return None
    for u in range(n):
        for v in range(u + 1, n):
            if bool(adjacency[u] & (1 << v)) != bool(adjacency[v] & (1 << u)):
                return None
    reached = 1
    while True:
        expanded = reached
        for vertex in range(n):
            if reached & (1 << vertex):
                expanded |= adjacency[vertex]
        if expanded == reached:
            break
        reached = expanded
    if reached != full:
        return None
    return n, adjacency, ids


def _maximal_independent_set(n: int, adjacency: list[int], ids: list[int]) -> int:
    white = (1 << n) - 1
    independent = 0
    while white:
        black = 0
        for vertex in range(n):
            bit = 1 << vertex
            if not white & bit:
                continue
            lower_white_neighbor = False
            for other in range(n):
                if (white & (1 << other) and adjacency[vertex] & (1 << other)
                        and ids[other] < ids[vertex]):
                    lower_white_neighbor = True
                    break
            if not lower_white_neighbor:
                black |= bit
        if black == 0:
            return -1
        independent |= black
        removed = black
        for vertex in range(n):
            if black & (1 << vertex):
                removed |= adjacency[vertex]
        white &= ~removed
    return independent


def _lex_shortest_path(source: int, target: int, n: int,
                       adjacency: list[int], ids: list[int]) -> list[int]:
    previous = [-2] * n
    previous[source] = -1
    queue = [source]
    head = 0
    while head < len(queue) and previous[target] == -2:
        vertex = queue[head]
        head += 1
        neighbors = [other for other in range(n) if adjacency[vertex] & (1 << other)]
        neighbors.sort(key=lambda other: ids[other])
        for other in neighbors:
            if previous[other] == -2:
                previous[other] = vertex
                queue.append(other)
    if previous[target] == -2:
        return []
    path = []
    vertex = target
    while vertex != -1:
        path.append(vertex)
        vertex = previous[vertex]
    path.reverse()
    return path


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
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    n, adjacency, ids = parsed
    independent = _maximal_independent_set(n, adjacency, ids)
    if independent < 0:
        return -1, b""
    connectors = 0
    independent_vertices = [vertex for vertex in range(n) if independent & (1 << vertex)]
    independent_vertices.sort(key=lambda vertex: ids[vertex])
    for position, source in enumerate(independent_vertices):
        for target in independent_vertices[position + 1:]:
            path = _lex_shortest_path(source, target, n, adjacency, ids)
            if len(path) <= 4:
                for vertex in path[1:-1]:
                    connectors |= 1 << vertex
    dominating = independent | connectors
    payload = struct.pack("<qq", independent, dominating)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
