"""Bounded deterministic Nagamochi–Ibaraki FOREST certificate profile."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MIN_K = 1
MAX_K = 3
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + MAX_M)


def _parse(values: Sequence[int]) -> tuple[int, int, int, list[tuple[int, int]]] | None:
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m, k = values[:3]
    if (not 3 <= n <= MAX_N or not 0 <= m <= MAX_M or not MIN_K <= k <= MAX_K
            or len(values) != 3 + 2 * m):
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(m):
        u, v = values[3 + 2 * index:5 + 2 * index]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, m, k, edges


def _forest_labels(n: int, edges: list[tuple[int, int]]) -> list[int]:
    rank = [0] * n
    scanned_vertex = [False] * n
    scanned_edge = [False] * len(edges)
    labels = [0] * len(edges)
    incident: list[list[int]] = [[] for _ in range(n)]
    for edge_id, (u, v) in enumerate(edges):
        incident[u].append(edge_id)
        incident[v].append(edge_id)

    for _ in range(n):
        x = min((vertex for vertex in range(n) if not scanned_vertex[vertex]),
                key=lambda vertex: (-rank[vertex], vertex))
        for edge_id in incident[x]:
            if scanned_edge[edge_id]:
                continue
            u, v = edges[edge_id]
            y = v if u == x else u
            labels[edge_id] = rank[y] + 1
            if rank[x] == rank[y]:
                rank[x] += 1
            rank[y] += 1
            scanned_edge[edge_id] = True
        scanned_vertex[x] = True
    return labels


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None
            and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, m, k, edges = parsed
    labels = _forest_labels(n, edges)
    output_labels = [label if label <= k else 0 for label in labels]
    payload = struct.pack("<" + "q" * (m + 1), m, *output_labels)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
