"""Object-tree reference for one-rotation-at-a-time move-to-root accesses."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


class _Node:
    __slots__ = ("key", "left", "right", "parent")

    def __init__(self, key: int):
        self.key = key
        self.left: _Node | None = None
        self.right: _Node | None = None
        self.parent: _Node | None = None


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return -1
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 51:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return -1
    initial_count = values[0]
    if not 0 <= initial_count <= 16:
        return -1
    query_offset = 1 + initial_count
    if len(values) < query_offset + 1:
        return -1
    access_count = values[query_offset]
    if not 0 <= access_count <= 32 or len(values) != query_offset + 1 + access_count:
        return -1
    initial = values[1:query_offset]
    queries = values[query_offset + 1:]
    if (any(not -100 <= key <= 100 for key in (*initial, *queries))
            or len(set(initial)) != len(initial)):
        return -1

    root: _Node | None = None
    for key in initial:
        node = _Node(key)
        if root is None:
            root = node
            continue
        current = root
        while True:
            if key < current.key:
                if current.left is None:
                    current.left = node
                    node.parent = current
                    break
                current = current.left
            else:
                if current.right is None:
                    current.right = node
                    node.parent = current
                    break
                current = current.right

    result = 0
    for query_number, query in enumerate(queries, 1):
        current = root
        comparisons = 0
        while current is not None:
            comparisons += 1
            if query == current.key:
                break
            current = current.left if query < current.key else current.right
        if current is not None:
            while current.parent is not None:
                old_parent = current.parent
                grandparent = old_parent.parent
                if old_parent.left is current:
                    old_parent.left = current.right
                    if current.right is not None:
                        current.right.parent = old_parent
                    current.right = old_parent
                else:
                    old_parent.right = current.left
                    if current.left is not None:
                        current.left.parent = old_parent
                    current.left = old_parent
                old_parent.parent = current
                current.parent = grandparent
                if grandparent is None:
                    root = current
                elif grandparent.left is old_parent:
                    grandparent.left = current
                else:
                    grandparent.right = current
        result += query_number * comparisons
    return result
