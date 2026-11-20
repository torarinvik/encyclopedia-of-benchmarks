"""Euler-interval/latest-occurrence oracle, independent of the sack method."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 2 <= input_length <= 130
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= 64 or input_length != 2 * n:
        return None
    parent = [-1] + list(values[1:n])
    color = list(values[n:2 * n])
    if any(not 0 <= parent[v] < v for v in range(1, n)):
        return None
    if any(not 0 <= value <= 255 for value in color):
        return None
    return n, parent, color


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, parent, color = parsed
    required = 8 * n
    if (type(output_is_null) is not bool or output_is_null or
            (capacity is not None and
             (type(capacity) is not int or capacity < required))):
        return -2, b""

    child = [[] for _ in range(n)]
    for vertex in range(1, n):
        child[parent[vertex]].append(vertex)
    order: list[int] = []
    tin = [0] * n
    end = [0] * n
    stack = [(0, False)]
    while stack:
        vertex, leaving = stack.pop()
        if leaving:
            end[vertex] = len(order)
            continue
        tin[vertex] = len(order)
        order.append(vertex)
        stack.append((vertex, True))
        for descendant in reversed(child[vertex]):
            stack.append((descendant, False))

    # A bounded Fenwick tree stores exactly the last occurrence of each color.
    bit = [0] * (n + 1)
    last: dict[int, int] = {}
    by_right: list[list[tuple[int, int]]] = [[] for _ in range(n + 1)]
    for vertex in range(n):
        by_right[end[vertex]].append((tin[vertex], vertex))
    answers = [0] * n

    def update(position: int, delta: int) -> None:
        index = position + 1
        while index <= n:
            bit[index] += delta
            index += index & -index

    def prefix(stop: int) -> int:
        total = 0
        index = stop
        while index:
            total += bit[index]
            index &= index - 1
        return total

    for right in range(n + 1):
        if right:
            vertex = order[right - 1]
            value = color[vertex]
            if value in last:
                update(last[value], -1)
            update(right - 1, 1)
            last[value] = right - 1
        for left, vertex in by_right[right]:
            answers[vertex] = prefix(right) - prefix(left)

    payload = b"".join(struct.pack("<q", count) for count in answers)
    return len(payload), payload


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]
