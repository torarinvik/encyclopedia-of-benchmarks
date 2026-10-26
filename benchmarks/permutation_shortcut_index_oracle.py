"""Bounded oracle for the shortcut index for permutation inverse queries."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_QUERIES = 16
MAX_INPUT_LENGTH = 52
MAX_OUTPUT_BYTES = 8 * MAX_QUERIES


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, stride = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= stride <= MAX_N or len(values) < n + 3:
        return None
    q = values[2 + n]
    if not 0 <= q <= MAX_QUERIES or len(values) != n + 3 + 2 * q:
        return None
    permutation = tuple(values[2:2 + n])
    if sorted(permutation) != list(range(1, n + 1)):
        return None
    queries = tuple((values[3 + n + 2 * i], values[4 + n + 2 * i]) for i in range(q))
    if any(op not in (0, 1) or not 1 <= index <= n for op, index in queries):
        return None
    return n, stride, tuple(value - 1 for value in permutation), queries


def _answers(n: int, stride: int, successor: Sequence[int], queries):
    visited = [False] * n
    marked = [False] * n
    back_pointer = [-1] * n
    for start in range(n):
        if visited[start]:
            continue
        cycle = []
        current = start
        while not visited[current]:
            visited[current] = True
            cycle.append(current)
            current = successor[current]
        if len(cycle) >= stride:
            for position in range(0, len(cycle), stride):
                vertex = cycle[position]
                marked[vertex] = True
                back_pointer[vertex] = cycle[(position - stride) % len(cycle)]

    # The bit vector B is ordered by vertex number; rank maps a marked bit to S.
    bit_vector = sum((1 << vertex) for vertex, flag in enumerate(marked) if flag)
    shortcuts = [back_pointer[vertex] for vertex in range(n) if marked[vertex]]

    def inverse(target: int) -> int:
        marker = target
        for _ in range(n):
            if marked[marker]:
                break
            marker = successor[marker]
        if not marked[marker]:
            previous = target
            current = successor[target]
            while current != target:
                previous, current = current, successor[current]
            return previous
        rank = (bit_vector & ((1 << marker) - 1)).bit_count()
        current = shortcuts[rank]
        previous = current
        current = successor[current]
        for _ in range(n):
            if current == target:
                return previous
            previous, current = current, successor[current]
        return -1

    results = []
    for op, index in queries:
        target = index - 1
        answer = successor[target] if op == 0 else inverse(target)
        results.append(answer + 1)
    return results


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, stride, successor, queries = parsed
    answers = _answers(n, stride, successor, queries)
    payload = struct.pack("<" + "q" * len(answers), *answers) if answers else b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
