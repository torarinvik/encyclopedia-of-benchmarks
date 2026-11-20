"""Tarjan biconnected-block reference for edge- and vertex-cacti."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT, MAX_M, MAX_N, MAX_PARSEABLE_INPUT_LENGTH,
)


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[list[tuple[int, int]]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for edge in range(m):
        u, v = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        pair = (min(u, v), max(u, v))
        if pair in seen:
            return None
        seen.add(pair)
        adjacency[u].append((v, edge))
        adjacency[v].append((u, edge))
    return n, adjacency


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency = parsed
    discovery = [0] * n
    low = [0] * n
    edge_stack: list[int] = []
    blocks: list[list[int]] = []
    clock = 0

    def visit(u: int, parent_edge: int) -> None:
        nonlocal clock
        clock += 1
        discovery[u] = low[u] = clock
        for v, edge in adjacency[u]:
            if edge == parent_edge:
                continue
            if discovery[v] == 0:
                edge_stack.append(edge)
                visit(v, edge)
                low[u] = min(low[u], low[v])
                if low[v] >= discovery[u]:
                    block: list[int] = []
                    while edge_stack:
                        item = edge_stack.pop()
                        block.append(item)
                        if item == edge:
                            break
                    blocks.append(block)
            elif discovery[v] < discovery[u]:
                edge_stack.append(edge)
                low[u] = min(low[u], discovery[v])

    for root in range(n):
        if discovery[root] == 0:
            visit(root, -1)

    vertex_cycle_uses = [0] * n
    cycles = 0
    edge_cactus = True
    vertex_cactus = True
    edge_ends = [(values[2 + 2 * e], values[3 + 2 * e]) for e in range((len(values) - 2) // 2)]
    for block in blocks:
        if len(block) == 1:
            continue
        degrees: dict[int, int] = {}
        for edge in block:
            u, v = edge_ends[edge]
            degrees[u] = degrees.get(u, 0) + 1
            degrees[v] = degrees.get(v, 0) + 1
        if len(block) != len(degrees) or any(degree != 2 for degree in degrees.values()):
            edge_cactus = False
            break
        cycles += 1
        for vertex in degrees:
            vertex_cycle_uses[vertex] += 1
            if vertex_cycle_uses[vertex] > 1:
                vertex_cactus = False
    if not edge_cactus:
        return 0
    return 4 * cycles + (2 if vertex_cactus else 0) + 1
