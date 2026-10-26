"""Bounded, deterministic k=2 Thorup--Zwick approximate distance oracle."""

from __future__ import annotations

import struct

MAX_VERTICES = 12
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_QUERIES = 32
MAX_WEIGHT = 1_000
MAX_INPUT_LENGTH = 4 + 3 * MAX_EDGES + 2 * MAX_QUERIES
MAX_OUTPUT_BYTES = 8 * (MAX_QUERIES + 1)
MAX_WORKSPACE_BYTES = 2_048
INVALID_RESULT = -1
OUTPUT_ERROR = -2
INF = 1 << 60


def _invalid(values: tuple[int, ...], input_length: int, input_is_null: bool) -> bool:
    if input_is_null or not 4 <= input_length <= MAX_INPUT_LENGTH or input_length != len(values):
        return True
    n, m, sample_mask = values[:3]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return True
    if sample_mask <= 0 or sample_mask >= (1 << n):
        return True
    q_index = 3 + 3 * m
    if q_index >= len(values):
        return True
    q = values[q_index]
    if not 0 <= q <= MAX_QUERIES or len(values) != q_index + 1 + 2 * q:
        return True
    seen: set[tuple[int, int]] = set()
    adjacency = [[] for _ in range(n)]
    for i in range(m):
        u, v, w = values[3 + 3 * i: 6 + 3 * i]
        if not (0 <= u < v < n and 1 <= w <= MAX_WEIGHT) or (u, v) in seen:
            return True
        seen.add((u, v))
        adjacency[u].append((v, w))
        adjacency[v].append((u, w))
    if n > 1:
        reached = {0}
        stack = [0]
        while stack:
            u = stack.pop()
            for v, _ in adjacency[u]:
                if v not in reached:
                    reached.add(v)
                    stack.append(v)
        if len(reached) != n:
            return True
    for i in range(q):
        u, v = values[q_index + 1 + 2 * i:q_index + 3 + 2 * i]
        if not (0 <= u < n and 0 <= v < n):
            return True
    return False


def _estimates(values: tuple[int, ...]) -> tuple[int, ...]:
    n, m, sample_mask = values[:3]
    q_index = 3 + 3 * m
    q = values[q_index]
    dist = [[INF] * n for _ in range(n)]
    for v in range(n):
        dist[v][v] = 0
    for i in range(m):
        u, v, w = values[3 + 3 * i: 6 + 3 * i]
        dist[u][v] = dist[v][u] = w
    for k in range(n):
        for i in range(n):
            for j in range(n):
                candidate = dist[i][k] + dist[k][j]
                if candidate < dist[i][j]:
                    dist[i][j] = candidate

    sample = [v for v in range(n) if sample_mask & (1 << v)]
    nearest_sample = [min(sample, key=lambda a: (dist[v][a], a)) for v in range(n)]
    nearest_distance = [dist[v][nearest_sample[v]] for v in range(n)]
    bunch = [set(sample) for _ in range(n)]
    for u in range(n):
        for x in range(n):
            if not (sample_mask & (1 << x)) and dist[u][x] < nearest_distance[u]:
                bunch[u].add(x)

    result = []
    for qi in range(q):
        u, v = values[q_index + 1 + 2 * qi:q_index + 3 + 2 * qi]
        for level in range(2):
            pivot = v if level == 0 else nearest_sample[v]
            if pivot in bunch[u]:
                result.append(dist[u][pivot] + dist[v][pivot])
                break
            u, v = v, u
        else:  # A_1 is nonempty, so every A_1 pivot belongs to every bunch.
            raise AssertionError("bounded k=2 oracle failed to find a bunch pivot")
    return tuple(result)


def expected_output(
    values: tuple[int, ...] | list[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return byte count/result and staged little-endian output."""
    values = tuple(values)
    if input_length is None:
        input_length = len(values)
    if _invalid(values, input_length, input_is_null):
        return INVALID_RESULT, b""
    estimates = _estimates(values)
    output = struct.pack("<q", len(estimates)) + b"".join(struct.pack("<q", d) for d in estimates)
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
