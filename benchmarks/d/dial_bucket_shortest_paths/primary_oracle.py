"""Primary cyclic-bucket oracle for bounded directed nonnegative shortest paths."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_VERTICES = 16
MAX_EDGES = 64
MAX_EDGE_WEIGHT = 8
BUCKET_COUNT = MAX_EDGE_WEIGHT + 1
MAX_DISTANCE = (MAX_VERTICES - 1) * MAX_EDGE_WEIGHT
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_VERTICES
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, tuple[tuple[int, int, int], ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m, source = values[:3]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if not 0 <= source < n or len(values) != 3 + 3 * m:
        return None
    edges: list[tuple[int, int, int]] = []
    for index in range(m):
        u, v, weight = values[3 + 3 * index: 6 + 3 * index]
        if not 0 <= u < n or not 0 <= v < n or not 0 <= weight <= MAX_EDGE_WEIGHT:
            return None
        edges.append((u, v, weight))
    return n, source, tuple(edges)


def _dial(n: int, source: int, edges: Sequence[tuple[int, int, int]]) -> list[int]:
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for u, v, weight in edges:
        adjacency[u].append((v, weight))

    distance = [MAX_DISTANCE + 1] * n
    settled = [False] * n
    distance[source] = 0

    # Each successful edge relaxation creates at most one queue record, plus source.
    record_vertex = [0] * (MAX_EDGES + 1)
    record_distance = [0] * (MAX_EDGES + 1)
    record_next = [-1] * (MAX_EDGES + 1)
    head = [-1] * BUCKET_COUNT
    tail = [-1] * BUCKET_COUNT
    used = 0

    def enqueue(vertex: int, value: int) -> None:
        nonlocal used
        record_vertex[used] = vertex
        record_distance[used] = value
        record_next[used] = -1
        bucket = value % BUCKET_COUNT
        if tail[bucket] < 0:
            head[bucket] = tail[bucket] = used
        else:
            record_next[tail[bucket]] = used
            tail[bucket] = used
        used += 1

    enqueue(source, 0)
    for current in range(MAX_DISTANCE + 1):
        bucket = current % BUCKET_COUNT
        while head[bucket] >= 0:
            entry = head[bucket]
            head[bucket] = record_next[entry]
            if head[bucket] < 0:
                tail[bucket] = -1
            vertex = record_vertex[entry]
            if record_distance[entry] != current or settled[vertex] or distance[vertex] != current:
                continue
            settled[vertex] = True
            for target, weight in adjacency[vertex]:
                candidate = current + weight
                if not settled[target] and candidate < distance[target]:
                    distance[target] = candidate
                    enqueue(target, candidate)

    return [-1 if value > MAX_DISTANCE else value for value in distance]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    n, source, edges = parsed
    required = 8 * n
    if output_is_null or capacity is not None and capacity < required:
        return -2, b""
    distances = _dial(n, source, edges)
    return required, struct.pack("<" + "q" * n, *distances)

