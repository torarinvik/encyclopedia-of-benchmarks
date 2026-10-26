"""Bounded deterministic index-based GBBS SCAN projection."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES
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
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    neighbors = [set() for _ in range(n)]
    for position in range(2, len(values), 2):
        u, v = values[position:position + 2]
        if not 0 <= u < v < n or v in neighbors[u]:
            return None
        neighbors[u].add(v)
        neighbors[v].add(u)
    return n, neighbors


def _similarity_parts(u: int, v: int, neighbors: list[set[int]]) -> tuple[int, int]:
    # Closed-neighborhood cosine: (common open neighbors + u + v) /
    # sqrt((degree(u)+1) * (degree(v)+1)).
    numerator = len(neighbors[u] & neighbors[v]) + 2
    denominator_squared = (len(neighbors[u]) + 1) * (len(neighbors[v]) + 1)
    return numerator, denominator_squared


def _epsilon_similar(numerator: int, denominator_squared: int) -> bool:
    # epsilon is fixed to 1/2. Squaring is exact because both sides are positive.
    return 4 * numerator * numerator >= denominator_squared


def _cluster(neighbors: list[set[int]]) -> list[int]:
    n = len(neighbors)
    core = [
        sum(_epsilon_similar(*_similarity_parts(u, v, neighbors))
            for v in neighbors[u]) >= 2
        for u in range(n)
    ]
    labels = [-1] * n

    # IndexBased::ClusterCores is connected components over similar core edges.
    # Starting roots in ID order gives each component its minimum core ID.
    for root in range(n):
        if not core[root] or labels[root] != -1:
            continue
        labels[root] = root
        queue = [root]
        cursor = 0
        while cursor < len(queue):
            u = queue[cursor]
            cursor += 1
            for v in sorted(neighbors[u]):
                if (core[v] and labels[v] == -1
                        and _epsilon_similar(*_similarity_parts(u, v, neighbors))):
                    labels[v] = root
                    queue.append(v)

    # The deterministic IndexBased mode attaches a non-core to its most similar
    # epsilon-similar core; equal similarities prefer the lowest core ID.
    for u in range(n):
        if core[u]:
            continue
        best_core = -1
        best_numerator = 0
        best_denominator_squared = 1
        for v in sorted(neighbors[u]):
            if not core[v]:
                continue
            numerator, denominator_squared = _similarity_parts(u, v, neighbors)
            if not _epsilon_similar(numerator, denominator_squared):
                continue
            left = numerator * numerator * best_denominator_squared
            right = best_numerator * best_numerator * denominator_squared
            if (best_core == -1 or left > right
                    or left == right and v < best_core):
                best_core = v
                best_numerator = numerator
                best_denominator_squared = denominator_squared
        if best_core != -1:
            labels[u] = labels[best_core]
    return labels


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
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    n, neighbors = parsed
    labels = _cluster(neighbors)
    encoded = b"".join(struct.pack("<q", label) for label in labels)
    if output_is_null or capacity is not None and capacity < len(encoded):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
