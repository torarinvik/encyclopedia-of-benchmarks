"""Direct edge-deletion connectivity model of reverse-delete MST."""

from __future__ import annotations

import struct

MAX_VERTICES = 8
MAX_EDGES = 20
MAX_VALID_INPUT = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT = MAX_VALID_INPUT + 1
OUTPUT_BYTES = 16
WORKSPACE_BYTES = 2048
INVALID = -1
NO_OUTPUT = -2


def _parse(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, m = values[0], values[1]
    if (not 2 <= n <= MAX_VERTICES or not n - 1 <= m <= MAX_EDGES
            or len(values) != 2 + 3 * m):
        return None
    edges = []
    pairs = set()
    for edge_id in range(m):
        u, v, weight = values[2 + 3 * edge_id:5 + 3 * edge_id]
        if not 0 <= u < n or not 0 <= v < n or u == v or not 0 <= weight <= 1000:
            return None
        pair = (min(u, v), max(u, v))
        if pair in pairs:
            return None
        pairs.add(pair)
        edges.append((u, v, weight))
    return n, edges


def _connected(n, edges, active):
    seen = [False] * n
    queue = [0]
    seen[0] = True
    for vertex in queue:
        for edge_id, (u, v, _weight) in enumerate(edges):
            if not (active >> edge_id) & 1:
                continue
            neighbor = v if u == vertex else u if v == vertex else -1
            if neighbor >= 0 and not seen[neighbor]:
                seen[neighbor] = True
                queue.append(neighbor)
    return all(seen)


def _run(values, input_length=None, input_is_null=False):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return None
    n, edges = parsed
    count = len(edges)
    active = (1 << count) - 1
    if not _connected(n, edges, active):
        return None
    order = sorted(range(count), key=lambda edge_id: (edges[edge_id][2], edge_id), reverse=True)
    for edge_id in order:
        candidate = active & ~(1 << edge_id)
        if _connected(n, edges, candidate):
            active = candidate
    weight = sum(edge[2] for edge_id, edge in enumerate(edges) if (active >> edge_id) & 1)
    return active, weight


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    result = _run(values, input_length, input_is_null)
    if result is None:
        return INVALID, b""
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < OUTPUT_BYTES)):
        return NO_OUTPUT, b""
    return OUTPUT_BYTES, struct.pack("<qq", result[0], result[1])
