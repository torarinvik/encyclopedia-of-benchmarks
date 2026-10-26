"""Independent active-graph verifier for the GBBS Barenboim-Elkin profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 20
MAX_EDGES = 190
MAX_INPUT_LENGTH = 382
MAX_OUTPUT_BYTES = 160


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
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


def _bkv12_cutoff(n: int, edges: list[tuple[int, int]]) -> int:
    active = set(range(n))
    best_num, best_den = 0, 1
    while active:
        degree = {vertex: 0 for vertex in active}
        for u, v in edges:
            if u in active and v in active:
                degree[u] += 1
                degree[v] += 1
        total = sum(degree.values())
        if total * best_den > best_num * len(active):
            best_num, best_den = total, len(active)
        removed = {vertex for vertex in active
                   if 10 * degree[vertex] * len(active) <= 11 * total}
        if not removed:
            return 1
        active.difference_update(removed)
    return max((best_num + 10 * best_den - 1) // (10 * best_den), 1)


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
    cutoff = _bkv12_cutoff(n, edges)
    active = set(range(n))
    order = []
    while active:
        degree = {vertex: 0 for vertex in active}
        for u, v in edges:
            if u in active and v in active:
                degree[u] += 1
                degree[v] += 1
        batch = sorted(vertex for vertex in active if degree[vertex] < cutoff)
        if not batch:
            batch = [min(active)]
        order.extend(batch)
        active.difference_update(batch)
    ranks = [0] * n
    for rank, vertex in enumerate(order):
        ranks[vertex] = rank
    output = b"".join(struct.pack("<q", rank) for rank in ranks)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
