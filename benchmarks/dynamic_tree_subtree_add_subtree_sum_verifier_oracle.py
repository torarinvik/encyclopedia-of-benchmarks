"""Independent matrix-and-queue verifier for dynamic subtree operations."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_Q = 32
MAX_DELTA = 1_000
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > 3 * MAX_N + 5 * MAX_Q + 1
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 3 * n + 5 * q:
        return None
    weights = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_DELTA for value in weights):
        return None
    graph = [[False] * n for _ in range(n)]
    at = 2 + n
    for _ in range(n - 1):
        u, v = values[at], values[at + 1]
        at += 2
        if not (0 <= u < n and 0 <= v < n and u != v) or graph[u][v]:
            return None
        graph[u][v] = graph[v][u] = True
    seen = {0}
    queue = [0]
    for u in queue:
        for v, linked in enumerate(graph[u]):
            if linked and v not in seen:
                seen.add(v)
                queue.append(v)
    if len(seen) != n:
        return None
    return n, q, weights, graph, at


def _walk(graph: list[list[bool]], start: int, blocked: tuple[int, int]) -> list[int]:
    n = len(graph)
    reached = [False] * n
    reached[start] = True
    queue = [start]
    for u in queue:
        for v in range(n):
            if ((u == blocked[0] and v == blocked[1])
                    or (u == blocked[1] and v == blocked[0])
                    or not graph[u][v] or reached[v]):
                continue
            reached[v] = True
            queue.append(v)
    return queue


def _answers(values, n, q, weights, graph, operation_start):
    answers: list[int] = []
    for i in range(q):
        at = operation_start + 5 * i
        kind, v, p, arg, reserved = values[at:at + 5]
        if kind == 0:
            w, x = arg, reserved
            if not (0 <= v < n and 0 <= p < n and 0 <= w < n and 0 <= x < n
                    and v != p and w != x and graph[v][p]):
                return None
            graph[v][p] = graph[p][v] = False
            if graph[w][x] or x in _walk(graph, w, (n, n)):
                return None
            graph[w][x] = graph[x][w] = True
        elif kind == 1:
            if not (0 <= v < n and 0 <= p < n and 0 <= arg <= MAX_DELTA
                    and reserved == 0 and graph[v][p]):
                return None
            for u in _walk(graph, v, (v, p)):
                weights[u] += arg
        elif kind == 2:
            if not (0 <= v < n and 0 <= p < n and arg == 0 and reserved == 0
                    and graph[v][p]):
                return None
            answers.append(sum(weights[u] for u in _walk(graph, v, (v, p))))
        else:
            return None
    return answers


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, q, weights, graph, start = parsed
    answers = _answers(values, n, q, weights, graph, start)
    if answers is None:
        return -1, b""
    cap = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(cap) is not int or cap < 0:
        return -2, b""
    required = 8 * len(answers)
    if required and (output_is_null or cap < required):
        return -2, b""
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    expected_result, expected = expected_output(
        values, output_capacity, output_is_null, input_is_null, input_length)
    return result == expected_result and output == expected
