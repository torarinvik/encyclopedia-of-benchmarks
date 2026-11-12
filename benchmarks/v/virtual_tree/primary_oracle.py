"""DFS-order adjacent-LCA construction for a bounded virtual tree."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 32
MAX_MARKED = 32
MAX_VALID_INPUT_LENGTH = 65
MAX_INPUT_LENGTH = 66
MAX_VIRTUAL_VERTICES = 32
MAX_CANDIDATES = 64
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_VIRTUAL_VERTICES)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, k = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= k <= min(n, MAX_MARKED):
        return None
    if len(values) != n + k + 1:
        return None
    parent = [0] * n
    for vertex in range(1, n):
        candidate = values[1 + vertex]
        if not 0 <= candidate < n or candidate == vertex:
            return None
        parent[vertex] = candidate
    marks = list(values[n + 1:])
    if any(not 0 <= vertex < n for vertex in marks) or len(set(marks)) != k:
        return None
    return n, parent, marks


def _metadata(n: int, parent: list[int]) -> tuple[list[int], list[int], list[int]] | None:
    children = [[] for _ in range(n)]
    for vertex in range(1, n):
        children[parent[vertex]].append(vertex)
    tin = [-1] * n
    tout = [-1] * n
    depth = [0] * n
    stack: list[tuple[int, int]] = [(0, 0)]
    timer = 0
    tin[0] = timer
    timer += 1
    reached = 1
    while stack:
        vertex, next_child = stack[-1]
        if next_child == len(children[vertex]):
            tout[vertex] = timer
            stack.pop()
            continue
        child = children[vertex][next_child]
        stack[-1] = (vertex, next_child + 1)
        if tin[child] != -1:
            return None
        tin[child] = timer
        timer += 1
        reached += 1
        depth[child] = depth[vertex] + 1
        stack.append((child, 0))
    if reached != n:
        return None
    return tin, tout, depth


def _lca(a: int, b: int, parent: list[int], depth: list[int]) -> int:
    while depth[a] > depth[b]:
        a = parent[a]
    while depth[b] > depth[a]:
        b = parent[b]
    while a != b:
        a = parent[a]
        b = parent[b]
    return a


def _build(n: int, parent: list[int], marks: list[int]) -> list[int] | None:
    metadata = _metadata(n, parent)
    if metadata is None:
        return None
    tin, tout, depth = metadata
    if not marks:
        return [0]
    ordered_marks = sorted(marks, key=tin.__getitem__)
    vertices = [0, *ordered_marks]
    for left, right in zip(ordered_marks, ordered_marks[1:]):
        vertices.append(_lca(left, right, parent, depth))
    vertices.sort(key=tin.__getitem__)
    unique: list[int] = []
    for vertex in vertices:
        if not unique or unique[-1] != vertex:
            unique.append(vertex)

    def is_ancestor(ancestor: int, descendant: int) -> bool:
        return tin[ancestor] <= tin[descendant] < tout[ancestor]

    stack: list[int] = []
    words = [len(unique)]
    for vertex in unique:
        while stack and not is_ancestor(stack[-1], vertex):
            stack.pop()
        if stack:
            virtual_parent = stack[-1]
        else:
            virtual_parent = vertex
        words.extend((vertex, virtual_parent, depth[vertex] - depth[virtual_parent]))
        stack.append(vertex)
    return words


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, b""
    words = _build(*decoded)
    if words is None:
        return -1, b""
    encoded = b"".join(struct.pack("<q", word) for word in words)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded
