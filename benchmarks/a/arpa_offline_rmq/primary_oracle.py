"""Arpa's offline RMQ: monotone next-smaller links plus DSU find."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 64
MAX_Q = 64
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_Q
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
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 2 * q:
        return None
    array = values[2:2 + n]
    if any(not -1000 <= value <= 1000 for value in array):
        return None
    queries = []
    for j in range(q):
        left, right = values[2 + n + 2 * j: 4 + n + 2 * j]
        if not 0 <= left <= right < n:
            return None
        queries.append((left, right))
    return tuple(array), tuple(queries)


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
    array, queries = decoded
    by_right: list[list[tuple[int, int]]] = [[] for _ in array]
    for ordinal, (left, right) in enumerate(queries):
        by_right[right].append((ordinal, left))
    parent = list(range(len(array)))
    monotone: list[int] = []
    answers = [0] * len(queries)
    for right, value in enumerate(array):
        while monotone and array[monotone[-1]] > value:
            parent[monotone.pop()] = right
        monotone.append(right)
        for ordinal, left in by_right[right]:
            answers[ordinal] = _find(parent, left)
    return sum((ordinal + 1) * (answer + 1)
               for ordinal, answer in enumerate(answers))
