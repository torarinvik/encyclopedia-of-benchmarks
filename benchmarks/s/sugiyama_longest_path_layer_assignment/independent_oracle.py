"""Topological dynamic-programming reference for sink-distance layers."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_EDGES,
    MAX_INPUT_WORDS,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_WORDS,
    MAX_VERTICES,
)


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_WORDS
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, m = values[:2]
    if not 0 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    adjacency = [[] for _ in range(n)]
    indegree = [0] * n
    seen = set()
    for edge in range(m):
        source, target = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= source < n or not 0 <= target < n or (source, target) in seen:
            return None
        seen.add((source, target))
        adjacency[source].append(target)
        indegree[target] += 1
    for neighbors in adjacency:
        neighbors.sort()
    return n, adjacency, indegree


def _serialize(words):
    return b"".join((word & ((1 << 64) - 1)).to_bytes(8, "little") for word in words)


def expected_output(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None or type(output_is_null) is not bool:
        return -1, b""
    n, adjacency, indegree = decoded
    ready = [vertex for vertex in range(n) if indegree[vertex] == 0]
    topological = []
    while ready:
        vertex = ready.pop(0)
        topological.append(vertex)
        for target in adjacency[vertex]:
            indegree[target] -= 1
            if indegree[target] == 0:
                ready.append(target)
                ready.sort()
    if len(topological) != n:
        return -1, b""

    distance_to_sink = [0] * n
    for vertex in reversed(topological):
        for target in adjacency[vertex]:
            distance_to_sink[vertex] = max(
                distance_to_sink[vertex], distance_to_sink[target] + 1)
    layer_count = max(distance_to_sink, default=-1) + 1
    layers = [layer_count - 1 - distance_to_sink[vertex] for vertex in range(n)]
    output = _serialize([layer_count, *layers])
    if (output_is_null or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(output))):
        return -2, b""
    return len(output), output


def expected_result(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    return expected_output(values, output_capacity, input_is_null,
                           output_is_null, input_length)[0]
