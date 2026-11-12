"""Direct edge-excluded traversal oracle for the dynamic subtree profile."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 32
MAX_Q = 64
MAX_VALUE = 1_000
MAX_VALID_INPUT_LENGTH = 3 * MAX_N + 5 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _edge(a: int, b: int) -> tuple[int, int]:
    return (a, b) if a < b else (b, a)


def _connected(n: int, edges: set[tuple[int, int]], start: int,
               goal: int) -> bool:
    todo = [start]
    seen = {start}
    for vertex in todo:
        for a, b in edges:
            if a == vertex:
                neighbor = b
            elif b == vertex:
                neighbor = a
            else:
                continue
            if neighbor == goal:
                return True
            if neighbor not in seen:
                seen.add(neighbor)
                todo.append(neighbor)
    return start == goal


def _side_sum(n: int, values: list[int], edges: set[tuple[int, int]],
              vertex: int, parent: int) -> int:
    todo = deque([vertex])
    seen = {vertex}
    total = 0
    while todo:
        current = todo.popleft()
        total += values[current]
        for a, b in edges:
            if (a == current and b == parent) or (a == parent and b == current):
                continue
            if a == current:
                neighbor = b
            elif b == current:
                neighbor = a
            else:
                continue
            if neighbor not in seen:
                seen.add(neighbor)
                todo.append(neighbor)
    return total


def _evaluate(values: Sequence[int] | None, input_is_null: bool,
              input_length: int | None):
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
    if any(not 0 <= item <= MAX_VALUE for item in current):
        return None
    edge_start = 2 + n
    edges: set[tuple[int, int]] = set()
    for index in range(n - 1):
        a, b = values[edge_start + 2 * index:edge_start + 2 * index + 2]
        if not (0 <= a < n and 0 <= b < n and a != b):
            return None
        edge = _edge(a, b)
        if edge in edges:
            return None
        edges.add(edge)
    if any(not _connected(n, edges, 0, vertex) for vertex in range(n)):
        return None

    operation_start = edge_start + 2 * (n - 1)
    answers: list[int] = []
    for index in range(q):
        offset = operation_start + 5 * index
        kind, a, b, c, d = values[offset:offset + 5]
        if kind == 0:
            if not (0 <= a < n and 0 <= b < n and 0 <= c < n and 0 <= d < n
                    and a != b and c != d):
                return None
            old = _edge(a, b)
            new = _edge(c, d)
            if old not in edges:
                return None
            edges.remove(old)
            if new in edges or _connected(n, edges, c, d):
                return None
            edges.add(new)
        elif kind == 1:
            if not (0 <= a < n and 0 <= b <= MAX_VALUE and c == 0 and d == 0):
                return None
            current[a] += b
        elif kind == 2:
            if not (0 <= a < n and 0 <= b < n and c == 0 and d == 0
                    and _edge(a, b) in edges):
                return None
            answers.append(_side_sum(n, current, edges, a, b))
        else:
            return None
    return answers


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return ABI result and little-endian answers for the fixed-width events.

    The input layout is ``[N,Q,values[N],edges[2*(N-1)],events[5*Q]]``.
    Event ``[0,u,v,w,x]`` replaces edge ``(u,v)`` with ``(w,x)``,
    ``[1,p,delta,0,0]`` adds to a value, and ``[2,v,p,0,0]`` queries the
    component side of ``v`` after excluding its adjacent parent edge ``(v,p)``.
    """
    answers = _evaluate(values, input_is_null, input_length)
    if answers is None:
        return INVALID_RESULT, b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return OUTPUT_ERROR_RESULT, b""
    required = 8 * len(answers)
    if required and (output_is_null or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload


def validate_output(values: Sequence[int] | None, output: bytes) -> bool:
    result, expected = expected_output(values, capacity=MAX_OUTPUT_BYTES)
    return result == len(expected) and output == expected
