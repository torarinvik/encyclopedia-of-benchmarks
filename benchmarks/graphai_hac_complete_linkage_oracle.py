"""Cluster-set oracle for GraphAIBench's bounded heap-based complete-linkage HAC."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 8
MAX_EDGES = 24
MAX_WEIGHT = 32
ROOT_PARENT = (1 << 32) - 1
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (4 * MAX_NODES - 2)
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[:2]
    if (not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES
            or len(values) != 2 + 3 * m):
        return None
    edges = []
    seen_pairs: set[tuple[int, int]] = set()
    seen_weights: set[int] = set()
    adjacency = [[] for _ in range(n)]
    for offset in range(2, len(values), 3):
        u, v, weight = values[offset : offset + 3]
        if (not 0 <= u < v < n or not 1 <= weight <= MAX_WEIGHT
                or (u, v) in seen_pairs or weight in seen_weights):
            return None
        seen_pairs.add((u, v))
        seen_weights.add(weight)
        edges.append((u, v, weight))
        adjacency[u].append(v)
        adjacency[v].append(u)
    if n > 1:
        reached = {0}
        frontier = [0]
        while frontier:
            u = frontier.pop()
            for v in adjacency[u]:
                if v not in reached:
                    reached.add(v)
                    frontier.append(v)
        if len(reached) != n:
            return None
    return n, edges


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    n, edges = parsed
    clusters = [{vertex} for vertex in range(n)]
    current_id = list(range(n))
    parents = [ROOT_PARENT] * (2 * n - 1)
    heights = [0] * (2 * n - 1)

    # Recompute cluster-pair scores directly from original crossing edges.
    # GraphAIBench preserves one-sided edges and applies min linkage on overlap.
    for merge in range(n - 1):
        best = None
        for left in range(len(clusters)):
            for right in range(left + 1, len(clusters)):
                crossing = [
                    weight for u, v, weight in edges
                    if ((u in clusters[left] and v in clusters[right])
                        or (v in clusters[left] and u in clusters[right]))
                ]
                if not crossing:
                    continue
                score = min(crossing)
                candidate = (score, -left, -right)
                if best is None or candidate > best[0]:
                    best = (candidate, left, right, score)
        if best is None:
            return INVALID_RESULT, b""
        _, left, right, score = best
        left_id, right_id = current_id[left], current_id[right]
        new_id = n + merge
        parents[left_id] = parents[right_id] = new_id
        heights[left_id] = heights[right_id] = score
        merged = clusters[left] | clusters[right]
        del clusters[right]
        del current_id[right]
        del clusters[left]
        del current_id[left]
        clusters.append(merged)
        current_id.append(new_id)

    output = b"".join(
        struct.pack("<qq", parents[node], heights[node])
        for node in range(2 * n - 1)
    )
    if output_is_null or capacity is not None and capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
