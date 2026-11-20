"""Parent-map closure reference for the bounded random-LT greedy trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

LIMIT_N = 8
LIMIT_M = 24
LIMIT_SCENARIOS = 8
SCALE = 256
MAX_WORDS = 4 + 3 * LIMIT_M + LIMIT_N * LIMIT_SCENARIOS + 1


def _decode(values: Sequence[int]):
    if len(values) < 4 or len(values) > MAX_WORDS:
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= (1 << 63)
           for item in values):
        return None
    n, m, k, scenarios = values[:4]
    if n < 1 or n > LIMIT_N or m < 0 or m > LIMIT_M:
        return None
    if k < 0 or k > n or scenarios < 1 or scenarios > LIMIT_SCENARIOS:
        return None
    if len(values) != 4 + 3 * m + n * scenarios:
        return None

    edge_rows: list[tuple[int, int, int]] = []
    pair_set: set[tuple[int, int]] = set()
    weight_sums = [0] * n
    for pos in range(m):
        u, v, weight = values[4 + 3 * pos:7 + 3 * pos]
        if u < 0 or u >= n or v < 0 or v >= n or u == v:
            return None
        if weight < 0 or weight > SCALE or (u, v) in pair_set:
            return None
        pair_set.add((u, v))
        weight_sums[v] += weight
        if weight_sums[v] > SCALE:
            return None
        edge_rows.append((u, v, weight))

    draw_offset = 4 + 3 * m
    random_tape = [values[draw_offset + i * n:draw_offset + (i + 1) * n]
                   for i in range(scenarios)]
    if any(draw < 0 or draw >= SCALE for row in random_tape for draw in row):
        return None
    return n, k, scenarios, edge_rows, random_tape


def _one_parent_per_world(n: int, edges: list[tuple[int, int, int]],
                          ticket_row: Sequence[int]) -> list[int]:
    incoming: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for source, target, weight in edges:
        incoming[target].append((source, weight))
    result = [-1] * n
    for vertex, ticket in enumerate(ticket_row):
        residual = ticket
        for source, weight in incoming[vertex]:
            if residual < weight:
                result[vertex] = source
                break
            residual -= weight
    return result


def _closure(n: int, parent: Sequence[int]) -> list[int]:
    descendants = [1 << vertex for vertex in range(n)]
    for child, source in enumerate(parent):
        if source >= 0:
            descendants[source] |= 1 << child
    for pivot in range(n):
        pivot_bit = 1 << pivot
        for source in range(n):
            if descendants[source] & pivot_bit:
                descendants[source] |= descendants[pivot]
    return descendants


def _spread(closure: Sequence[int], seeds: int) -> int:
    union = 0
    for source, reachable in enumerate(closure):
        if seeds & (1 << source):
            union |= reachable
    return union.bit_count()


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or not 0 <= input_length <= MAX_WORDS):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, budget, scenarios, edges, ticket_rows = decoded
    closures = [_closure(n, _one_parent_per_world(n, edges, row))
                for row in ticket_rows]

    chosen = 0
    trace: list[int] = []
    for _ in range(budget):
        old = [_spread(world, chosen) for world in closures]
        winner = -1
        winner_gain = -1
        for candidate in range(n):
            bit = 1 << candidate
            if chosen & bit:
                continue
            gain = sum(_spread(world, chosen | bit) - old[index]
                       for index, world in enumerate(closures))
            if gain > winner_gain:
                winner, winner_gain = candidate, gain
        if winner < 0:
            return -1, b""
        chosen |= 1 << winner
        trace.extend((winner, winner_gain))

    encoded = b"".join(struct.pack("<q", value) for value in (budget, *trace))
    if output_is_null or capacity is not None and capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
