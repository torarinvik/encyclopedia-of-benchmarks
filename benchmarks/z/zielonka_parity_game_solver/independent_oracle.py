"""Exhaustive positional-strategy reference for bounded parity games."""

from __future__ import annotations

from collections.abc import Iterator, Sequence


def _strategy_choices(vertices: list[int], adjacency: list[tuple[int, ...]],
                      vertex_count: int) -> Iterator[tuple[int, ...]]:
    chosen = [0] * vertex_count

    def visit(index: int) -> Iterator[tuple[int, ...]]:
        if index == len(vertices):
            yield tuple(chosen)
            return
        vertex = vertices[index]
        for destination in adjacency[vertex]:
            chosen[vertex] = destination
            yield from visit(index + 1)

    yield from visit(0)


def _fixed_profile_winners(next_vertex: tuple[int, ...], priorities: list[int],
                           vertex_count: int) -> int:
    even_mask = 0
    for start in range(vertex_count):
        first_position: dict[int, int] = {}
        play: list[int] = []
        current = start
        while current not in first_position:
            first_position[current] = len(play)
            play.append(current)
            current = next_vertex[current]
        cycle = play[first_position[current]:]
        if min(priorities[vertex] for vertex in cycle) % 2 == 0:
            even_mask |= 1 << start
    return even_mask


def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, Sequence) or len(values) < 6 or len(values) > 59:
        return -1
    if any(type(value) is not int for value in values):
        return -1
    vertex_count, edge_count = values[:2]
    if (not 1 <= vertex_count <= 8 or not vertex_count <= edge_count <= 20
            or len(values) != 2 + 2 * vertex_count + 2 * edge_count):
        return -1
    owners: list[int] = []
    priorities: list[int] = []
    cursor = 2
    for _ in range(vertex_count):
        owner, priority = values[cursor:cursor + 2]
        cursor += 2
        if owner not in (0, 1) or not 0 <= priority <= 5:
            return -1
        owners.append(owner)
        priorities.append(priority)
    outgoing = [[] for _ in range(vertex_count)]
    seen_edges: set[tuple[int, int]] = set()
    for _ in range(edge_count):
        source, destination = values[cursor:cursor + 2]
        cursor += 2
        edge = (source, destination)
        if (not 0 <= source < vertex_count or not 0 <= destination < vertex_count
                or edge in seen_edges):
            return -1
        seen_edges.add(edge)
        outgoing[source].append(destination)
    if any(not successors for successors in outgoing):
        return -1
    adjacency = [tuple(successors) for successors in outgoing]

    even_vertices = [vertex for vertex in range(vertex_count) if owners[vertex] == 0]
    odd_vertices = [vertex for vertex in range(vertex_count) if owners[vertex] == 1]
    even_strategies = tuple(_strategy_choices(even_vertices, adjacency, vertex_count))
    odd_strategies = tuple(_strategy_choices(odd_vertices, adjacency, vertex_count))
    winning_mask = 0
    for even_strategy in even_strategies:
        guaranteed = (1 << vertex_count) - 1
        for odd_strategy in odd_strategies:
            profile = tuple(
                even_strategy[v] if owners[v] == 0 else odd_strategy[v]
                for v in range(vertex_count)
            )
            guaranteed &= _fixed_profile_winners(profile, priorities, vertex_count)
            if guaranteed == 0:
                break
        winning_mask |= guaranteed
    return winning_mask
