"""Independent selected-edge-component verifier for GBBS Shiloach–Vishkin forest."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_NODES = 12
MAX_EDGES = 24
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = MAX_EDGES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _components_from_selected_edges(n: int, edges: list[tuple[int, int]],
                                    selected: list[bool]) -> list[int]:
    adjacent = [[] for _ in range(n)]
    for edge_index, (u, v) in enumerate(edges):
        if selected[edge_index]:
            adjacent[u].append(v)
            adjacent[v].append(u)
    labels = [-1] * n
    for root in range(n):
        if labels[root] >= 0:
            continue
        labels[root] = root
        queue = deque([root])
        while queue:
            vertex = queue.popleft()
            for neighbor in adjacent[vertex]:
                if labels[neighbor] < 0:
                    labels[neighbor] = root
                    queue.append(neighbor)
    return labels


def _expected_mask(n: int, edges: list[tuple[int, int]]) -> bytes:
    selected = [False] * len(edges)
    for _ in range(n):
        component = _components_from_selected_edges(n, edges, selected)
        best_lower = [n] * n
        for u, v in edges:
            left, right = component[u], component[v]
            if left != right:
                lower, higher = sorted((left, right))
                if lower < best_lower[higher]:
                    best_lower[higher] = lower
        changed = False
        for higher, lower in enumerate(best_lower):
            if lower == n:
                continue
            for edge_index, (u, v) in enumerate(edges):
                if {component[u], component[v]} == {higher, lower}:
                    selected[edge_index] = True
                    changed = True
                    break
        if not changed:
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
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return -1, b""
    edges = []
    seen = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or (u, v) in seen:
            return -1, b""
        seen.add((u, v))
        edges.append((u, v))
    result = _expected_mask(n, edges)
    if output_is_null or capacity is not None and capacity < m:
        return -2, b""
    return m, result
