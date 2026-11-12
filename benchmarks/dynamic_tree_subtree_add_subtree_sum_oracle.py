"""Direct edge-side traversal oracle for dynamic subtree addition and sum."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_Q = 32
MAX_DELTA = 1_000
MAX_VALID_INPUT_LENGTH = 3 * MAX_N + 5 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _edge(a: int, b: int) -> tuple[int, int]:
    return (a, b) if a < b else (b, a)


def _reachable(n: int, edges: set[tuple[int, int]], start: int,
               goal: int) -> bool:
    todo = [start]
    seen = {start}
    for vertex in todo:
        for a, b in edges:
            other = b if a == vertex else a if b == vertex else -1
            if other < 0:
                continue
            if other == goal:
                return True
            if other not in seen:
                seen.add(other)
                todo.append(other)
    return start == goal


def _component(n: int, edges: set[tuple[int, int]], start: int,
               blocked: tuple[int, int]) -> list[int]:
    todo = [start]
    seen = {start}
    for vertex in todo:
        for a, b in edges:
            if (a, b) == blocked:
                continue
            other = b if a == vertex else a if b == vertex else -1
            if other >= 0 and other not in seen:
                seen.add(other)
                todo.append(other)
    return todo


def _evaluate(values: Sequence[int] | None, input_is_null: bool,
              input_length: int | None) -> list[int] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 3 * n + 5 * q:
        return None
    current = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_DELTA for value in current):
        return None
    edge_start = 2 + n
    edges: set[tuple[int, int]] = set()
    for i in range(n - 1):
        a, b = values[edge_start + 2 * i:edge_start + 2 * i + 2]
        if not (0 <= a < n and 0 <= b < n and a != b):
            return None
        edge = _edge(a, b)
        if edge in edges:
            return None
        edges.add(edge)
    if any(not _reachable(n, edges, 0, vertex) for vertex in range(n)):
        return None

    operation_start = edge_start + 2 * (n - 1)
    answers: list[int] = []
    for i in range(q):
        at = operation_start + 5 * i
        kind, v, p, delta, reserved = values[at:at + 5]
        if kind == 0:
            w, x = delta, reserved
            if not (0 <= v < n and 0 <= p < n and 0 <= w < n and 0 <= x < n
                    and v != p and w != x):
                return None
            old, new = _edge(v, p), _edge(w, x)
            if old not in edges:
                return None
            edges.remove(old)
            if _reachable(n, edges, w, x):
                return None
            edges.add(new)
        elif kind == 1:
            if not (0 <= v < n and 0 <= p < n and 0 <= delta <= MAX_DELTA
                    and reserved == 0 and _edge(v, p) in edges):
                return None
            for vertex in _component(n, edges, v, _edge(v, p)):
                current[vertex] += delta
        elif kind == 2:
            if not (0 <= v < n and 0 <= p < n and delta == 0 and reserved == 0
                    and _edge(v, p) in edges):
                return None
            answers.append(sum(current[u] for u in _component(n, edges, v, _edge(v, p))))
        else:
            return None
    return answers


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    answers = _evaluate(values, input_is_null, input_length)
    if answers is None:
        return -1, b""
    cap = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(cap) is not int or cap < 0):
        return -2, b""
    required = 8 * len(answers)
    if required and (output_is_null or cap < required):
        return -2, b""
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload


def validate_output(values: Sequence[int] | None, output: bytes) -> bool:
    result, expected = expected_output(values, capacity=MAX_OUTPUT_BYTES)
    return result == len(expected) and output == expected
