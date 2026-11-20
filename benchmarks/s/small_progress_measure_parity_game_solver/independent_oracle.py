"""Positional-strategy enumeration for bounded parity games."""

from __future__ import annotations

from collections.abc import Iterator, Sequence

MAX_VERTICES = 8
MAX_EDGES = 20
MAX_PRIORITY = 5
MAX_PARSEABLE_INPUT_LENGTH = 59


def _choices(vertices: list[int], outgoing: list[list[int]], n: int) -> Iterator[tuple[int, ...]]:
    selected = [0] * n

    def visit(position: int) -> Iterator[tuple[int, ...]]:
        if position == len(vertices):
            yield tuple(selected)
            return
        vertex = vertices[position]
        for destination in outgoing[vertex]:
            selected[vertex] = destination
            yield from visit(position + 1)

    yield from visit(0)


def _winner_mask(next_vertex: tuple[int, ...], priorities: list[int], n: int) -> int:
    mask = 0
    for start in range(n):
        first: dict[int, int] = {}
        path: list[int] = []
        vertex = start
        while vertex not in first:
            first[vertex] = len(path)
            path.append(vertex)
            vertex = next_vertex[vertex]
        cycle = path[first[vertex]:]
        if min(priorities[item] for item in cycle) % 2 == 0:
            mask |= 1 << start
    return mask


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or not 6 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1
    n, m = values[:2]
    if not 1 <= n <= MAX_VERTICES or not n <= m <= MAX_EDGES:
        return -1
    if len(values) != 2 + 2 * n + 2 * m:
        return -1
    owners: list[int] = []
    priorities: list[int] = []
    cursor = 2
    for _ in range(n):
        owner, priority = values[cursor:cursor + 2]
        cursor += 2
        if owner not in (0, 1) or not 0 <= priority <= MAX_PRIORITY:
            return -1
        owners.append(owner)
        priorities.append(priority)
    outgoing = [[] for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for _ in range(m):
        source, destination = values[cursor:cursor + 2]
        cursor += 2
        edge = (source, destination)
        if not 0 <= source < n or not 0 <= destination < n or edge in seen:
            return -1
        seen.add(edge)
        outgoing[source].append(destination)
    if any(not destinations for destinations in outgoing):
        return -1

    even_vertices = [v for v in range(n) if owners[v] == 0]
    odd_vertices = [v for v in range(n) if owners[v] == 1]
    odd_strategies = tuple(_choices(odd_vertices, outgoing, n))
    winning = 0
    for even_strategy in _choices(even_vertices, outgoing, n):
        guaranteed = (1 << n) - 1
        for odd_strategy in odd_strategies:
            next_vertex = tuple(even_strategy[v] if owners[v] == 0 else odd_strategy[v]
                                for v in range(n))
            guaranteed &= _winner_mask(next_vertex, priorities, n)
            if guaranteed == 0:
                break
        winning |= guaranteed
    return winning
