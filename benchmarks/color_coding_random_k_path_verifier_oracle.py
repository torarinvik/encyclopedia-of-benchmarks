"""Independent lexicographic DFS verifier for explicit Color Coding trials."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 12
MAX_M = 66
MAX_K = 6
MAX_TRIALS = 8
MAX_INPUT_LENGTH = 232
MAX_OUTPUT_BYTES = 64


def _trial_path(n: int, k: int, adjacency: list[list[int]], colors: list[int]) -> tuple[int, ...] | None:
    def visit(vertex: int, used_vertices: int, used_colors: int,
              path: tuple[int, ...]) -> tuple[int, ...] | None:
        if len(path) == k:
            return path
        for neighbor in adjacency[vertex]:
            vertex_bit = 1 << neighbor
            color_bit = 1 << colors[neighbor]
            if used_vertices & vertex_bit or used_colors & color_bit:
                continue
            result = visit(neighbor, used_vertices | vertex_bit, used_colors | color_bit,
                           path + (neighbor,))
            if result is not None:
                return result
        return None

    for start in range(n):
        result = visit(start, 1 << start, 1 << colors[start], (start,))
        if result is not None:
            return result
    return None


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return invalid, b""
    if (not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return invalid, b""
    n, m, k, trials = values[:4]
    if (not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or not 1 <= k <= min(MAX_K, n)
            or not 1 <= trials <= MAX_TRIALS):
        return invalid, b""
    color_start = 4 + 2 * m
    if len(values) != color_start + n * trials:
        return invalid, b""
    graph = [[] for _ in range(n)]
    edges = set()
    for at in range(4, color_start, 2):
        a, b = values[at:at + 2]
        edge = (min(a, b), max(a, b))
        if a < 0 or b < 0 or a >= n or b >= n or a == b or edge in edges:
            return invalid, b""
        edges.add(edge)
        graph[a].append(b)
        graph[b].append(a)
    for neighbors in graph:
        neighbors.sort()
    colorings = [values[color_start + t * n:color_start + (t + 1) * n]
                 for t in range(trials)]
    if any(c < 0 or c >= k for row in colorings for c in row):
        return invalid, b""
    answer = [0, 0]
    for trial, colors in enumerate(colorings, 1):
        path = _trial_path(n, k, graph, colors)
        if path is not None:
            answer = [1, trial, *path]
            break
    payload = struct.pack("<" + "q" * len(answer), *answer)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
