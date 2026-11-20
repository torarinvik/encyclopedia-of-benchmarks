"""Exhaustive spanning-tree reference with rank-based tie selection."""

from __future__ import annotations

from itertools import combinations
import struct

BAD = -1
NO_OUTPUT = -2
MAX_N = 8
MAX_M = 20
MAX_INPUT = 63
RESULT_SIZE = 16
WORKSPACE_BYTES = 2048


def _decode(data, length, null):
    if (type(null) is not bool or null or not isinstance(data, (list, tuple))
            or not 2 <= len(data) <= MAX_INPUT
            or any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in data)
            or length is not None and (type(length) is not int or length != len(data))):
        return None
    n, m = data[0], data[1]
    if not 2 <= n <= MAX_N or not n - 1 <= m <= MAX_M or len(data) != 2 + 3 * m:
        return None
    edges = []
    pairs = set()
    for i in range(m):
        u, v, w = data[2 + 3 * i:5 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v or not 0 <= w <= 1000:
            return None
        pair = tuple(sorted((u, v)))
        if pair in pairs:
            return None
        pairs.add(pair)
        edges.append((u, v, w))
    return n, edges


def _tree_for_subset(n, edges, selected):
    parent = list(range(n))
    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for edge_id in selected:
        u, v, _ = edges[edge_id]
        a, b = find(u), find(v)
        if a == b:
            return False
        parent[a] = b
    root = find(0)
    return all(find(vertex) == root for vertex in range(n))


def _solve(data, length, null):
    parsed = _decode(data, length, null)
    if parsed is None:
        return None
    n, edges = parsed
    processing_order = sorted(range(len(edges)),
                              key=lambda i: (edges[i][2], i), reverse=True)
    best_key = None
    best_mask = None
    for chosen in combinations(range(len(edges)), n - 1):
        if not _tree_for_subset(n, edges, chosen):
            continue
        weight = sum(edges[i][2] for i in chosen)
        # Earlier reverse-delete candidates prefer an absent bit on equal cost.
        decision_bits = tuple(int(edge_id in chosen) for edge_id in processing_order)
        key = (weight, decision_bits)
        if best_key is None or weight < best_key[0] or (weight == best_key[0] and decision_bits < best_key[1]):
            best_key = key
            best_mask = sum(1 << i for i in chosen)
    if best_key is None:
        return None
    return best_mask, best_key[0]


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    result = _solve(values, input_length, input_is_null)
    if result is None:
        return BAD, b""
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < RESULT_SIZE)):
        return NO_OUTPUT, b""
    return RESULT_SIZE, struct.pack("<qq", result[0], result[1])
