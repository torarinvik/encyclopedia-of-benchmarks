"""All-sources BFS reference for the bounded tree-center workload."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Callable, Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 2 * (MAX_N - 1)
MAX_OUTPUT_BYTES = 16


def _graph(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values) or not 1 <= size <= MAX_INPUT_LENGTH:
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or size != 2 * n - 1:
        return None
    graph = [set() for _ in range(n)]
    for offset in range(1, size, 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < n or not 0 <= right < n or left == right:
            return None
        if right in graph[left]:
            return None
        graph[left].add(right)
        graph[right].add(left)
    seen = {0}
    queue = deque([0])
    while queue:
        vertex = queue.popleft()
        for neighbor in graph[vertex]:
            if neighbor not in seen:
                seen.add(neighbor)
                queue.append(neighbor)
    if len(seen) != n:
        return None
    return graph


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    graph = _graph(values, input_is_null, input_length)
    if graph is None:
        return -1, b""
    eccentricities = []
    for start in range(len(graph)):
        distances = {start: 0}
        queue = deque([start])
        while queue:
            vertex = queue.popleft()
            for neighbor in graph[vertex]:
                if neighbor not in distances:
                    distances[neighbor] = distances[vertex] + 1
                    queue.append(neighbor)
        eccentricities.append(max(distances.values()))
    best = min(eccentricities)
    centers = [vertex for vertex, eccentricity in enumerate(eccentricities)
               if eccentricity == best]
    encoded = b"".join(struct.pack("<q", center) for center in centers)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded


def verify_candidate(candidate: Callable[..., tuple[int, bytes]],
                     values: Sequence[int], expected: tuple[int, bytes] | None = None) -> bool:
    if expected is None:
        expected = expected_output(values)
    return candidate(values, len(values)) == expected
