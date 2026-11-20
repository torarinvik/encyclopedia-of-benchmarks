"""Recolor each queried component by direct graph traversal."""

from __future__ import annotations

from .primary_oracle import I64_MAX, I64_MIN, MAX_N, MAX_Q, MAX_PARSEABLE_INPUT_LENGTH


def expected_result(values, input_is_null=False, input_length=None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) < 2:
        return -1
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + 3 * q:
        return -1
    edges: list[tuple[int, int]] = []
    checksum = 0
    query_ordinal = 0
    for j in range(q):
        opcode, first, second = values[2 + 3 * j: 5 + 3 * j]
        if opcode == 0:
            if not 0 <= first < n or not 0 <= second < n:
                return -1
            edges.append((first, second))
            continue
        if opcode != 1 or not 0 <= first < n or second != 0:
            return -1
        adjacency: list[list[int]] = [[] for _ in range(n)]
        for left, right in edges:
            adjacency[left].append(right)
            adjacency[right].append(left)
        color = [-1] * n
        color[first] = 0
        stack = [first]
        is_bipartite = True
        while stack:
            node = stack.pop()
            for neighbor in adjacency[node]:
                if color[neighbor] == -1:
                    color[neighbor] = color[node] ^ 1
                    stack.append(neighbor)
                elif color[neighbor] == color[node]:
                    is_bipartite = False
        answer = 1 if is_bipartite else 0
        checksum += (query_ordinal + 1) * (answer + 1)
        query_ordinal += 1
    return checksum
