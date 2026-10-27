"""Independent selected-edge BFS verifier for contraction components."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 16
MAX_M = 24
MAX_INPUT = 74


def _parse_graph(values: Sequence[int]) -> tuple[int, list[tuple[int, int, int]]] | None:
    if len(values) < 5 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m = values[0], values[1]
    if not 2 <= n <= MAX_N or not n-1 <= m <= MAX_M or len(values) != 2+3*m:
        return None
    edges = [tuple(values[2+3*i:5+3*i]) for i in range(m)]
    seen_pairs: set[tuple[int, int]] = set()
    for u, v, bit in edges:
        if not 0 <= u < v < n or bit not in (0, 1) or (u, v) in seen_pairs:
            return None
        seen_pairs.add((u, v))
    todo = [0]
    reached = {0}
    while todo:
        vertex = todo.pop()
        for u, v, _ in edges:
            other = v if u == vertex else u if v == vertex else -1
            if other >= 0 and other not in reached:
                reached.add(other)
                todo.append(other)
    if len(reached) != n:
        return None
    return n, edges


def _components_by_scan(n: int, edges: list[tuple[int, int, int]]) -> bytes:
    representative = [-1] * n
    for seed in range(n):
        if representative[seed] >= 0:
            continue
        component: list[int] = []
        queue = deque([seed])
        representative[seed] = seed
        while queue:
            current = queue.popleft()
            component.append(current)
            for u, v, selected in edges:
                if not selected:
                    continue
                neighbor = v if u == current else u if v == current else -1
                if neighbor >= 0 and representative[neighbor] < 0:
                    representative[neighbor] = seed
                    queue.append(neighbor)
        minimum = min(component)
        for vertex in component:
            representative[vertex] = minimum
    return b"".join(struct.pack("<i", value) for value in representative)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _parse_graph(values)
    if parsed is None:
        return -1, b""
    payload = _components_by_scan(*parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
