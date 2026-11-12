"""Small direct-graph oracle for dynamic vertex-add component sums."""

import struct
from collections import deque
from typing import Sequence

MAX_N = 16
MAX_Q = 32
MAX_VALUE = 100
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_Q * 8
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _root_component_sum(n: int, values: list[int], edges: set[tuple[int, int]],
                        source: int) -> int:
    adjacency = [[] for _ in range(n)]
    for left, right in edges:
        adjacency[left].append(right)
        adjacency[right].append(left)
    seen = {source}
    todo = deque([source])
    total = 0
    while todo:
        vertex = todo.popleft()
        total += values[vertex]
        for neighbor in adjacency[vertex]:
            if neighbor not in seen:
                seen.add(neighbor)
                todo.append(neighbor)
    return total


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return ``(result, payload)`` for ``[n,q,initial_values,(op,a,b)*q]``.

    Event forms are add-edge ``[0,u,v]``, remove-edge ``[1,u,v]``,
    vertex-add ``[2,v,x]``, and component-sum query ``[3,v,0]``. The oracle
    maintains the graph directly and runs a fresh BFS for each query.
    """
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return INVALID_RESULT, b""
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return INVALID_RESULT, b""
    if len(values) != 2 + n + 3 * q:
        return INVALID_RESULT, b""
    current = list(values[2:2 + n])
    if any(not 0 <= x <= MAX_VALUE for x in current):
        return INVALID_RESULT, b""

    edges: set[tuple[int, int]] = set()
    answers: list[int] = []
    events = values[2 + n:]
    for index in range(q):
        op, a, b = events[3 * index:3 * index + 3]
        if op in (0, 1):
            if not 0 <= a < n or not 0 <= b < n or a == b:
                return INVALID_RESULT, b""
            edge = (a, b) if a < b else (b, a)
            if op == 0:
                if edge in edges:
                    return INVALID_RESULT, b""
                edges.add(edge)
            else:
                if edge not in edges:
                    return INVALID_RESULT, b""
                edges.remove(edge)
        elif op == 2:
            if not 0 <= a < n or not 0 <= b <= MAX_VALUE:
                return INVALID_RESULT, b""
            current[a] += b
        elif op == 3:
            if not 0 <= a < n or b != 0:
                return INVALID_RESULT, b""
            answers.append(_root_component_sum(n, current, edges, a))
        else:
            return INVALID_RESULT, b""

    required = 8 * len(answers)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return OUTPUT_ERROR_RESULT, b""
    if output_is_null or effective_capacity < required:
        return OUTPUT_ERROR_RESULT, b""
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
