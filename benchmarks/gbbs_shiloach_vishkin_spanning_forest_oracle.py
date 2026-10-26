"""Source-stage oracle for GBBS Shiloach–Vishkin forest edge hooks."""

from __future__ import annotations

from collections.abc import Sequence

MAX_NODES = 12
MAX_EDGES = 24
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = MAX_EDGES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * m:
        return None
    edges = []
    seen = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def _find(parent: list[int], vertex: int) -> int:
    while parent[vertex] != vertex:
        parent[vertex] = parent[parent[vertex]]
        vertex = parent[vertex]
    return vertex


def _forest_mask(n: int, edges: list[tuple[int, int]]) -> bytes:
    parent = list(range(n))
    selected = [False] * len(edges)
    rounds = 0
    while True:
        previous = [_find(parent, vertex) for vertex in range(n)]
        next_parent = previous.copy()
        best_lower = [n] * n
        for u, v in edges:
            root_u, root_v = previous[u], previous[v]
            if root_u == root_v:
                continue
            lower, higher = sorted((root_u, root_v))
            if previous[higher] == higher and lower < best_lower[higher]:
                best_lower[higher] = lower

        changed = False
        for higher in range(n):
            lower = best_lower[higher]
            if lower == n:
                continue
            next_parent[higher] = lower
            for edge_index, (u, v) in enumerate(edges):
                if {previous[u], previous[v]} == {higher, lower}:
                    selected[edge_index] = True
                    break
            changed = True

        parent = next_parent
        for vertex in range(n):
            _find(parent, vertex)
        rounds += 1
        if not changed or rounds > n:
            break
    return bytes(int(flag) for flag in selected)


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    if output_is_null or capacity is not None and capacity < len(edges):
        return -2, b""
    return len(edges), _forest_mask(n, edges)
