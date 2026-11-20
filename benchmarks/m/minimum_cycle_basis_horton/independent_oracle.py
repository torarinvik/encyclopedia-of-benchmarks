"""All-simple-cycle minimum-basis reference for small undirected graphs."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import INVALID_RESULT, _parse, _cycle_weight
except ImportError:  # Support direct execution from the package directory.
    from primary_oracle import INVALID_RESULT, _parse, _cycle_weight


def _all_simple_cycles(n: int, edges: tuple[tuple[int, int, int], ...]) -> list[int]:
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for edge_id, (u, v, _) in enumerate(edges):
        adjacency[u].append((v, edge_id))
        adjacency[v].append((u, edge_id))
    cycles: set[int] = set()

    for start in range(n):
        visited = {start}

        def visit(vertex: int, edge_mask: int) -> None:
            for neighbor, edge_id in adjacency[vertex]:
                if neighbor == start:
                    if edge_mask.bit_count() >= 2:
                        cycles.add(edge_mask | (1 << edge_id))
                elif neighbor > start and neighbor not in visited:
                    visited.add(neighbor)
                    visit(neighbor, edge_mask | (1 << edge_id))
                    visited.remove(neighbor)

        visit(start, 0)
    return sorted(cycles, key=lambda mask: (_cycle_weight(mask, edges), mask))


def _basis_weight(cycles: Sequence[int], edges: tuple[tuple[int, int, int], ...], n: int) -> int:
    dimension = len(edges) - n + 1
    pivots = [0] * len(edges)
    rank = 0
    total = 0
    for cycle in cycles:
        residual = cycle
        for bit in range(len(edges) - 1, -1, -1):
            if residual >> bit & 1:
                if pivots[bit]:
                    residual ^= pivots[bit]
                else:
                    pivots[bit] = residual
                    rank += 1
                    total += _cycle_weight(cycle, edges)
                    break
        if rank == dimension:
            return total
    return 0 if dimension == 0 else INVALID_RESULT


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, edges = parsed
    return _basis_weight(_all_simple_cycles(n, edges), edges, n)
