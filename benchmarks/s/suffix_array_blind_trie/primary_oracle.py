"""Blind-trie insertion and ordered leaf traversal for bounded suffixes."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 32
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH * 8
WORKSPACE_BYTES = 2304
MAX_NODES = 2 * MAX_TEXT_LENGTH


def _symbol(text: Sequence[int], start: int, depth: int) -> int:
    index = start + depth
    return 0 if index >= len(text) else text[index] + 1


def _lcp(text: Sequence[int], left: int, right: int) -> int:
    depth = 0
    while _symbol(text, left, depth) == _symbol(text, right, depth):
        depth += 1
    return depth


def _blind_trie_order(text: Sequence[int]) -> list[int]:
    n = len(text)
    if n == 0:
        return []

    is_leaf = [False] * MAX_NODES
    split = [0] * MAX_NODES
    leaf_start = [-1] * MAX_NODES
    edge_symbol = [0] * MAX_NODES
    first_child = [-1] * MAX_NODES
    next_sibling = [-1] * MAX_NODES
    node_count = 0

    def new_leaf(start: int) -> int:
        nonlocal node_count
        node = node_count
        node_count += 1
        is_leaf[node] = True
        leaf_start[node] = start
        return node

    def new_internal(depth: int) -> int:
        nonlocal node_count
        node = node_count
        node_count += 1
        split[node] = depth
        return node

    def link_sorted(parent: int, child: int) -> None:
        symbol = edge_symbol[child]
        previous = -1
        cursor = first_child[parent]
        while cursor >= 0 and edge_symbol[cursor] < symbol:
            previous = cursor
            cursor = next_sibling[cursor]
        next_sibling[child] = cursor
        if previous < 0:
            first_child[parent] = child
        else:
            next_sibling[previous] = child

    def find_exact(parent: int, symbol: int) -> int:
        cursor = first_child[parent]
        while cursor >= 0:
            if edge_symbol[cursor] == symbol:
                return cursor
            if edge_symbol[cursor] > symbol:
                return -1
            cursor = next_sibling[cursor]
        return -1

    root = new_leaf(0)
    for start in range(1, n):
        # Blind descent uses only stored branch positions. If a branch symbol
        # is absent, follow the first ordered edge and repair after leaf LCP.
        leaf = root
        while not is_leaf[leaf]:
            symbol = _symbol(text, start, split[leaf])
            child = find_exact(leaf, symbol)
            if child < 0:
                child = first_child[leaf]
            leaf = child

        old_start = leaf_start[leaf]
        common = _lcp(text, start, old_start)
        new_suffix = new_leaf(start)

        if is_leaf[root]:
            parent = new_internal(common)
            edge_symbol[root] = _symbol(text, old_start, common)
            edge_symbol[new_suffix] = _symbol(text, start, common)
            link_sorted(parent, root)
            link_sorted(parent, new_suffix)
            root = parent
            continue

        # The blind search may have reached a leaf from the wrong interval.
        # Re-traverse branch positions below the true LCP, then splice at the
        # first node whose common-prefix length reaches the mismatch.
        parent = -1
        current = root
        while not is_leaf[current] and split[current] < common:
            symbol = _symbol(text, start, split[current])
            child = find_exact(current, symbol)
            if child < 0:
                # This cannot occur below the computed common prefix; retain a
                # bounded fallback so the reference remains total.
                child = first_child[current]
            parent = current
            current = child

        if not is_leaf[current] and split[current] == common:
            edge_symbol[new_suffix] = _symbol(text, start, common)
            link_sorted(current, new_suffix)
            continue

        middle = new_internal(common)
        if parent < 0:
            root = middle
        else:
            previous = -1
            cursor = first_child[parent]
            while cursor != current:
                previous = cursor
                cursor = next_sibling[cursor]
            next_sibling[middle] = next_sibling[current]
            if previous < 0:
                first_child[parent] = middle
            else:
                next_sibling[previous] = middle
            edge_symbol[middle] = edge_symbol[current]

        edge_symbol[current] = _symbol(text, old_start, common)
        edge_symbol[new_suffix] = _symbol(text, start, common)
        link_sorted(middle, current)
        link_sorted(middle, new_suffix)

    ordered: list[int] = []
    stack = [root]
    while stack:
        node = stack.pop()
        if is_leaf[node]:
            ordered.append(leaf_start[node])
            continue
        children: list[int] = []
        child = first_child[node]
        while child >= 0:
            children.append(child)
            child = next_sibling[child]
        stack.extend(reversed(children))
    return ordered


def _decode(
    values: Sequence[int] | None, input_is_null: bool, input_length: int | None
) -> list[int] | None:
    if type(input_is_null) is not bool or type(input_length) not in (int, type(None)):
        return None
    if input_length is not None and not 0 <= input_length <= MAX_INPUT_LENGTH:
        return None
    if input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    if any(not 0 <= value <= 255 for value in values[1:]):
        return None
    return list(values)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity < 0)
    ):
        return -1, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    n = decoded[0]
    payload = struct.pack("<" + "q" * n, *_blind_trie_order(decoded[1:]))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
