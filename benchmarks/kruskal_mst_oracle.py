"""Independent Prim oracle for the bounded JavaScript/R Kruskal workload."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_VERTICES = 64
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
WEIGHT_MIN = -1_000_000
WEIGHT_MAX = 1_000_000
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def _hash_result(vertex_count: int, edges: list[tuple[int, int, int]]) -> int:
    ordered = sorted(edges, key=lambda edge: edge[2])
    payload = bytearray(struct.pack("<HH", vertex_count, len(ordered)))
    total = 0
    for left, right, weight in ordered:
        payload.extend(struct.pack("<HHi", left, right, weight))
        total += weight
    payload.extend(struct.pack("<q", total))
    digest = FNV_OFFSET
    for byte in payload:
        digest = ((digest ^ byte) * FNV_PRIME) & MASK64
    return digest & MASK63


def expected_result(values: Sequence[int] | None) -> int:
    """Return the normalized MST hash, or -1 for an invalid graph packet."""
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1
    if len(values) != 2 + 3 * edge_count or len(values) > MAX_VALID_INPUT_LENGTH:
        return -1
    maximum_for_graph = vertex_count * (vertex_count - 1) // 2
    if edge_count > maximum_for_graph:
        return -1
    if vertex_count == 1:
        if edge_count != 0:
            return -1
        return _hash_result(vertex_count, [])
    if edge_count < vertex_count - 1:
        return -1

    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(vertex_count)]
    seen_pairs: set[tuple[int, int]] = set()
    seen_weights: set[int] = set()
    edges: list[tuple[int, int, int]] = []
    for index in range(edge_count):
        offset = 2 + 3 * index
        left, right, weight = values[offset : offset + 3]
        if not (0 <= left < vertex_count and 0 <= right < vertex_count):
            return -1
        if left == right or not WEIGHT_MIN <= weight <= WEIGHT_MAX:
            return -1
        pair = (min(left, right), max(left, right))
        if pair in seen_pairs or weight in seen_weights:
            return -1
        seen_pairs.add(pair)
        seen_weights.add(weight)
        edges.append((pair[0], pair[1], weight))
        adjacency[left].append((right, weight))
        adjacency[right].append((left, weight))

    # Prim's cut scan is independent of the pinned Kruskal/DSU implementations.
    visited = [False] * vertex_count
    visited[0] = True
    accepted: list[tuple[int, int, int]] = []
    while len(accepted) < vertex_count - 1:
        best: tuple[int, int, int] | None = None
        for left in range(vertex_count):
            if not visited[left]:
                continue
            for right, weight in adjacency[left]:
                if not visited[right] and (best is None or weight < best[2]):
                    a, b = min(left, right), max(left, right)
                    best = (a, b, weight)
        if best is None:
            return -1
        accepted.append(best)
        visited[best[1] if visited[best[0]] else best[0]] = True
    return _hash_result(vertex_count, accepted)
