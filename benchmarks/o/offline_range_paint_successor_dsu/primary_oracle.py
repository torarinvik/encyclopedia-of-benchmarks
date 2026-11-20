"""Reverse-time range painting with a successor DSU over unpainted cells."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 64
MAX_Q = 64
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + 3 * q:
        return None
    operations = []
    for j in range(q):
        left, right, color = values[2 + 3 * j: 5 + 3 * j]
        if not 0 <= left <= right < n or not -1000 <= color <= 1000:
            return None
        operations.append((left, right, color))
    return n, tuple(operations)


def _find(parent: list[int], node: int) -> int:
    root = node
    while parent[root] != root:
        root = parent[root]
    while parent[node] != node:
        following = parent[node]
        parent[node] = root
        node = following
    return root


def expected_result(values, input_is_null=False, input_length=None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, operations = decoded
    parent = list(range(n + 1))
    final = [0] * n
    for left, right, color in reversed(operations):
        cell = _find(parent, left)
        while cell <= right:
            final[cell] = color
            parent[cell] = _find(parent, cell + 1)
            cell = parent[cell]
    return sum((index + 1) * (color + 1001) for index, color in enumerate(final))
