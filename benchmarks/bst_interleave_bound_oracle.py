"""Subtree-mask oracle for Wilber's interleave lower bound."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 8
MAX_ACCESSES = 16
MAX_INPUT_LENGTH = 36


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, root = values[0], values[1]
    if not 1 <= n <= MAX_NODES or not 0 <= root < n:
        return None
    edge_end = 2 + 2 * n
    if edge_end + 1 > len(values):
        return None
    left = list(values[2:edge_end:2])
    right = list(values[3:edge_end:2])
    for node in range(n):
        for child in (left[node], right[node]):
            if child < -1 or child >= n or child == node:
                return None
        if left[node] >= 0 and left[node] == right[node]:
            return None
    access_count = values[edge_end]
    if not 0 <= access_count <= MAX_ACCESSES or len(values) != edge_end + 1 + access_count:
        return None
    accesses = list(values[edge_end + 1:])
    if any(not 0 <= key < n for key in accesses):
        return None

    parents = [0] * n
    for node in range(n):
        for child in (left[node], right[node]):
            if child >= 0:
                parents[child] += 1
    if parents[root] != 0 or any(parents[node] != 1 for node in range(n) if node != root):
        return None
    subtree_masks = [0] * n
    visited = [False] * n

    def visit(node: int, low: int, high: int) -> int | None:
        if node < 0:
            return 0
        if not low <= node <= high or visited[node]:
            return None
        visited[node] = True
        left_mask = visit(left[node], low, node - 1)
        if left_mask is None:
            return None
        right_mask = visit(right[node], node + 1, high)
        if right_mask is None:
            return None
        subtree_masks[node] = left_mask | right_mask | (1 << node)
        return subtree_masks[node]

    if visit(root, 0, n - 1) is None or not all(visited):
        return None
    return n, left, right, accesses, subtree_masks


def _payload(parsed) -> bytes:
    n, _left, _right, accesses, subtree_masks = parsed
    bound = 0
    for node in range(n):
        previous = None
        for key in accesses:
            if subtree_masks[node] & (1 << key):
                label = 0 if key <= node else 1
                if previous is not None and label != previous:
                    bound += 1
                previous = label
    return struct.pack("<q", bound)


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
    payload = _payload(parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
