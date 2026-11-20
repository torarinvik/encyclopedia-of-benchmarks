"""Parent-conflict and disjoint-set reference for directed tree repair."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_VALID_INPUT_LENGTH = 33
MAX_PARSEABLE_INPUT_LENGTH = 34
INVALID_RESULT = -1


def _edges(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63)
                   for v in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 3 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for i in range(n):
        u, v = values[1 + 2 * i:3 + 2 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _edges(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, edges = decoded
    parent_of = [-1] * n
    first_parent_edge = -1
    second_parent_edge = -1
    for edge_id, (_, child) in enumerate(edges):
        if parent_of[child] == -1:
            parent_of[child] = edge_id
        else:
            first_parent_edge = parent_of[child]
            second_parent_edge = edge_id
            break

    parent = list(range(n))
    size = [1] * n

    def find(node: int) -> int:
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    cycle_edge = -1
    for edge_id, (u, v) in enumerate(edges):
        if edge_id == second_parent_edge:
            continue
        a, b = find(u), find(v)
        if a == b:
            cycle_edge = edge_id
            break
        if size[a] < size[b]:
            a, b = b, a
        parent[b] = a
        size[a] += size[b]

    if cycle_edge >= 0:
        return first_parent_edge if second_parent_edge >= 0 else cycle_edge
    return second_parent_edge
