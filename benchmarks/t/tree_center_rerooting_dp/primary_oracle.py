"""Rerooting-DP reference for the bounded tree-center workload."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 2 * (MAX_N - 1)
MAX_OUTPUT_BYTES = 16


def _tree(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[list[list[int]], list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 1 <= length <= MAX_INPUT_LENGTH:
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or length != 2 * n - 1:
        return None
    graph = [[] for _ in range(n)]
    for offset in range(1, length, 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < n or not 0 <= right < n or left == right:
            return None
        graph[left].append(right)
        graph[right].append(left)

    parent = [-2] * n
    parent[0] = -1
    order = [0]
    for vertex in order:
        for neighbor in graph[vertex]:
            if neighbor == parent[vertex]:
                continue
            if parent[neighbor] != -2:
                return None
            parent[neighbor] = vertex
            order.append(neighbor)
    if len(order) != n:
        return None
    return graph, parent, order


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    tree = _tree(values, input_is_null, input_length)
    if tree is None:
        return -1, b""
    graph, parent, order = tree
    n = len(graph)
    down = [0] * n
    first_height = [0] * n
    second_height = [0] * n
    first_child = [-1] * n
    for vertex in reversed(order):
        for child in graph[vertex]:
            if parent[child] != vertex:
                continue
            branch = down[child] + 1
            if branch > first_height[vertex]:
                second_height[vertex] = first_height[vertex]
                first_height[vertex] = branch
                first_child[vertex] = child
            elif branch > second_height[vertex]:
                second_height[vertex] = branch
        down[vertex] = first_height[vertex]

    outside = [-1] * n
    for vertex in order:
        for child in graph[vertex]:
            if parent[child] != vertex:
                continue
            sibling_height = (second_height[vertex]
                              if first_child[vertex] == child
                              else first_height[vertex])
            outside[child] = 1 + max(outside[vertex], sibling_height)

    eccentricities = [max(down[v], outside[v]) for v in range(n)]
    radius = min(eccentricities)
    centers = [v for v, value in enumerate(eccentricities) if value == radius]
    payload = b"".join(struct.pack("<q", center) for center in centers)
    output_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(output_capacity) is not int
            or output_capacity < 0 or output_is_null or output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
