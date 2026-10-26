"""Bounded deterministic worklist first-fit/conflict-resolution oracle."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_COLOR = 128
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
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
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if len(values) < 2:
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + 2 * m:
        return -1, b""
    adjacency = [[False] * n for _ in range(n)]
    edges = set()
    for index in range(2, len(values), 2):
        left, right = values[index:index + 2]
        if not 0 <= left < right < n or (left, right) in edges:
            return -1, b""
        edges.add((left, right))
        adjacency[left][right] = adjacency[right][left] = True
    colors = [MAX_COLOR] * n
    pending = list(range(n))
    rounds = 0
    while pending:
        rounds += 1
        if rounds > n + 1:
            return -1, b""
        prior = colors[:]
        for vertex in pending:
            forbidden = {prior[neighbor] for neighbor in range(n)
                         if adjacency[vertex][neighbor]
                         and prior[neighbor] != MAX_COLOR}
            color = next((candidate for candidate in range(MAX_COLOR)
                          if candidate not in forbidden), None)
            if color is None:
                return -1, b""
            colors[vertex] = color
        conflicts = set()
        for vertex in pending:
            for neighbor in range(vertex + 1, n):
                if adjacency[vertex][neighbor] and colors[vertex] == colors[neighbor]:
                    conflicts.add(vertex)
        for vertex in conflicts:
            colors[vertex] = MAX_COLOR
        pending = sorted(conflicts)
    output = b"".join(struct.pack("<q", color) for color in colors)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
