"""Direct root-path-union oracle for virtual-tree edge certificates."""

from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_INPUT_LENGTH,
    MAX_MARKED,
    MAX_OUTPUT_BYTES,
    MAX_VERTICES,
)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[int], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX
           for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    n, count = values[0], values[1]
    if type(n) is not int or type(count) is not int:
        return None
    if not 1 <= n <= MAX_VERTICES or not 0 <= count <= min(n, MAX_MARKED):
        return None
    if len(values) != n + count + 1:
        return None
    parent = [0] * n
    for vertex in range(1, n):
        p = values[vertex + 1]
        if type(p) is not int or p < 0 or p >= n or p == vertex:
            return None
        parent[vertex] = p
    marked = list(values[n + 1:])
    if any(type(v) is not int or v < 0 or v >= n for v in marked):
        return None
    if len(set(marked)) != count:
        return None
    return n, parent, marked


def _direct_certificate(n: int, parent: list[int], marked: list[int]) -> list[int] | None:
    # Validate the rooted tree and record depth and preorder by a direct child walk.
    children = [[] for _ in range(n)]
    for vertex in range(1, n):
        children[parent[vertex]].append(vertex)
    order: list[int] = []
    depth = [0] * n
    pending = [0]
    seen = [False] * n
    seen[0] = True
    while pending:
        vertex = pending.pop()
        order.append(vertex)
        for child in reversed(children[vertex]):
            if seen[child]:
                return None
            seen[child] = True
            depth[child] = depth[vertex] + 1
            pending.append(child)
    if len(order) != n:
        return None
    if not marked:
        return [0]

    # The union of root-to-mark paths contains exactly the Steiner subtree.
    union: set[int] = {0}
    for endpoint in marked:
        current = endpoint
        for _ in range(n):
            union.add(current)
            if current == 0:
                break
            current = parent[current]
        else:
            return None

    active_child_count = [0] * n
    for vertex in union:
        if vertex != 0 and parent[vertex] in union:
            active_child_count[parent[vertex]] += 1
    terminals = set(marked)
    kept = [v for v in order
            if v in union and (v == 0 or v in terminals or active_child_count[v] >= 2)]
    tin = [0] * n
    for index, vertex in enumerate(order):
        tin[vertex] = index

    words = [len(kept)]
    for vertex in kept:
        if vertex == 0:
            virtual_parent = 0
        else:
            ancestors = [candidate for candidate in kept
                         if candidate != vertex and depth[candidate] < depth[vertex]
                         and tin[candidate] <= tin[vertex]
                         and tin[vertex] < tin[candidate] + _subtree_size(candidate, children)]
            virtual_parent = max(ancestors, key=depth.__getitem__)
        words.extend((vertex, virtual_parent, depth[vertex] - depth[virtual_parent]))
    return words


def _subtree_size(root: int, children: list[list[int]]) -> int:
    count = 0
    stack = [root]
    while stack:
        vertex = stack.pop()
        count += 1
        stack.extend(children[vertex])
    return count


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    words = _direct_certificate(*parsed)
    if words is None:
        return -1, b""
    encoded = b"".join(struct.pack("<q", value) for value in words)
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(actual_capacity) is not int
            or actual_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > actual_capacity:
        return -2, b""
    return len(encoded), encoded
