"""Subset/endpoint DP oracle for the bounded randomized Color Coding replay."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 12
MAX_M = 66
MAX_K = 6
MAX_TRIALS = 8
MAX_INPUT_LENGTH = 232
MAX_OUTPUT_BYTES = 64


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m, k, trials = values[:4]
    if (not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or not 1 <= k <= min(MAX_K, n)
            or not 1 <= trials <= MAX_TRIALS):
        return None
    edge_start = 4
    color_start = edge_start + 2 * m
    if len(values) != color_start + trials * n:
        return None
    adjacency = [0] * n
    edges = set()
    for at in range(edge_start, color_start, 2):
        a, b = values[at:at + 2]
        edge = (min(a, b), max(a, b))
        if a < 0 or b < 0 or a >= n or b >= n or a == b or edge in edges:
            return None
        edges.add(edge)
        adjacency[a] |= 1 << b
        adjacency[b] |= 1 << a
    colors = [list(values[color_start + trial * n:color_start + (trial + 1) * n])
              for trial in range(trials)]
    if any(color < 0 or color >= k for row in colors for color in row):
        return None
    return n, k, trials, adjacency, colors


def _find_dp(n: int, k: int, adjacency: list[int], colors: list[int]) -> tuple[int, ...] | None:
    states: list[list[tuple[int, ...] | None]] = [[None] * n for _ in range(1 << k)]
    for vertex in range(n):
        states[1 << colors[vertex]][vertex] = (vertex,)
    full = (1 << k) - 1
    for mask in range(1, full + 1):
        for vertex in range(n):
            prefix = states[mask][vertex]
            if prefix is None:
                continue
            neighbors = adjacency[vertex]
            for next_vertex in range(n):
                color_bit = 1 << colors[next_vertex]
                if (neighbors >> next_vertex) & 1 and not mask & color_bit:
                    next_mask = mask | color_bit
                    candidate = prefix + (next_vertex,)
                    old = states[next_mask][next_vertex]
                    if old is None or candidate < old:
                        states[next_mask][next_vertex] = candidate
    candidates = [states[full][v] for v in range(n) if states[full][v] is not None]
    return min(candidates) if candidates else None


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
    if input_is_null or values is None:
        return invalid, b""
    decoded = _decode(values)
    if decoded is None:
        return invalid, b""
    n, k, trials, adjacency, colors = decoded
    result = [0, 0]
    for trial in range(trials):
        path = _find_dp(n, k, adjacency, colors[trial])
        if path is not None:
            result = [1, trial + 1, *path]
            break
    payload = struct.pack("<" + "q" * len(result), *result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
