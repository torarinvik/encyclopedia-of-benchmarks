"""Priority-extrema round oracle for Pannotia's bounded graph coloring modes."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_PRIORITY = 99_999_998
MAX_INPUT_LENGTH = 3 + MAX_NODES + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (tuple, list)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if len(values) < 3:
        return -1, b""
    n, m, mode = values[:3]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or mode not in (0, 1):
        return -1, b""
    if len(values) != 3 + n + 2 * m:
        return -1, b""
    priorities = list(values[3:3 + n])
    if (any(not 0 <= priority <= MAX_PRIORITY for priority in priorities)
            or len(set(priorities)) != n):
        return -1, b""
    adjacency = [0] * n
    degree = [0] * n
    seen = set()
    for offset in range(3 + n, len(values), 2):
        u, v = values[offset:offset + 2]
        if not (0 <= u < v < n) or (u, v) in seen:
            return -1, b""
        seen.add((u, v))
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u
        degree[u] += 1
        degree[v] += 1
    # Pannotia's kernels skip neighbor comparison when a vertex's CSR row has
    # exactly one entry; that case can assign the same color to both ends.
    if any(value == 1 for value in degree):
        return -1, b""

    colors = [-1] * n
    active = [True] * n
    color = 1
    while any(active):
        chosen = [False] * n
        for vertex in range(n):
            if not active[vertex]:
                continue
            active_neighbors = [other for other in range(n)
                               if active[other] and (adjacency[vertex] >> other) & 1]
            maximum = max((priorities[other] for other in active_neighbors), default=-1)
            if priorities[vertex] > maximum:
                colors[vertex] = color
                chosen[vertex] = True
            if mode == 1:
                minimum = min((priorities[other] for other in active_neighbors),
                              default=99_999_999)
                if priorities[vertex] < minimum:
                    colors[vertex] = color + 1
                    chosen[vertex] = True
        if not any(chosen):
            return -1, b""
        for vertex in range(n):
            if chosen[vertex]:
                active[vertex] = False
        color += 2 if mode == 1 else 1
    output = b"".join(struct.pack("<q", value) for value in colors)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
