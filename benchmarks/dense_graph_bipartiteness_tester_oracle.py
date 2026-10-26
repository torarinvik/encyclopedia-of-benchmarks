"""Primary BFS oracle for the dense-model bipartiteness tester profile."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 64
MAX_Q = 16
MAX_INPUT = 82
MASK64 = (1 << 64) - 1


def _payload(accepted: int, queries: int) -> bytes:
    return struct.pack("<qq", accepted, queries)


def _parse(values: Sequence[int] | None, input_is_null: bool, input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= min(n, MAX_Q) or len(values) != 2 + n + q:
        return None
    rows = values[2:2 + n]
    draws = values[2 + n:]
    for i, row in enumerate(rows):
        if n < 64 and (row < 0 or row >> n):
            return None
        bits = row & MASK64
        if (bits >> i) & 1:
            return None
    for i in range(n):
        for j in range(i + 1, n):
            if ((rows[i] & MASK64) >> j) & 1 != ((rows[j] & MASK64) >> i) & 1:
                return None
    for i, draw in enumerate(draws):
        if not 0 <= draw < n - i:
            return None
    return n, q, rows, draws


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, q, rows, draws = parsed
    remaining = list(range(n))
    sample = []
    for i, draw in enumerate(draws):
        selected = i + draw
        remaining[i], remaining[selected] = remaining[selected], remaining[i]
        sample.append(remaining[i])

    adjacent = [[False] * q for _ in range(q)]
    for i in range(q):
        row = rows[sample[i]] & MASK64
        for j in range(i + 1, q):
            adjacent[i][j] = adjacent[j][i] = bool((row >> sample[j]) & 1)

    color = [-1] * q
    accepted = 1
    for start in range(q):
        if color[start] != -1:
            continue
        color[start] = 0
        queue = deque([start])
        while queue:
            vertex = queue.popleft()
            for neighbor in range(q):
                if not adjacent[vertex][neighbor]:
                    continue
                if color[neighbor] == -1:
                    color[neighbor] = color[vertex] ^ 1
                    queue.append(neighbor)
                elif color[neighbor] == color[vertex]:
                    accepted = 0
    payload = _payload(accepted, q * (q - 1) // 2)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
