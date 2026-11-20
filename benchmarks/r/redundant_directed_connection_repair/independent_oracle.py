"""Independent reverse-deletion reference for directed arborescence repair."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import INVALID_RESULT, _edges


def _is_arborescence(n: int, edges: list[tuple[int, int]], omitted: int) -> bool:
    incoming = [0] * n
    adjacency = [[] for _ in range(n)]
    remaining = 0
    for edge_id, (u, v) in enumerate(edges):
        if edge_id == omitted:
            continue
        incoming[v] += 1
        adjacency[u].append(v)
        remaining += 1
    if remaining != n - 1:
        return False
    roots = [node for node, degree in enumerate(incoming) if degree == 0]
    if len(roots) != 1 or any(degree != 1 for node, degree in enumerate(incoming) if node != roots[0]):
        return False
    seen = {roots[0]}
    queue = [roots[0]]
    for node in queue:
        for neighbor in adjacency[node]:
            if neighbor not in seen:
                seen.add(neighbor)
                queue.append(neighbor)
    return len(seen) == n


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _edges(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, edges = decoded
    for edge_id in range(n - 1, -1, -1):
        if _is_arborescence(n, edges, edge_id):
            return edge_id
    return INVALID_RESULT
