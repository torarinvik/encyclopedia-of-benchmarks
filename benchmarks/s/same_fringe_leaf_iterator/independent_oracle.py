"""Recursive validation and complete leaf-list reference for same fringe."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import INVALID_RESULT, MAX_NODES_PER_TREE, MAX_PARSEABLE_INPUT_LENGTH


def _split(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values):
        return None
    left_size, right_size = values[0], values[1]
    if not (1 <= left_size <= MAX_NODES_PER_TREE
            and 1 <= right_size <= MAX_NODES_PER_TREE
            and len(values) == 2 + 3 * (left_size + right_size)):
        return None
    return left_size, right_size, 2, 2 + 3 * left_size


def _collect(values: Sequence[int], offset: int, node_count: int) -> list[int] | None:
    leaves: list[int] = []
    seen: set[int] = set()
    parent_count = [0] * node_count

    def visit(node: int) -> bool:
        if node < 0 or node >= node_count or node in seen:
            return False
        seen.add(node)
        base = offset + 3 * node
        left, right = values[base + 1], values[base + 2]
        if left == -1 and right == -1:
            leaves.append(values[base])
            return True
        if not (0 <= left < node_count and 0 <= right < node_count) or left == right:
            return False
        for child in (left, right):
            if child == 0:
                return False
            parent_count[child] += 1
            if parent_count[child] != 1:
                return False
        return visit(left) and visit(right)

    if not visit(0) or len(seen) != node_count or parent_count[0] != 0:
        return None
    if any(parent_count[node] != 1 for node in range(1, node_count)):
        return None
    return leaves


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    frame = _split(values, input_is_null, input_length)
    if frame is None:
        return INVALID_RESULT
    n_a, n_b, offset_a, offset_b = frame
    fringe_a = _collect(values, offset_a, n_a)
    fringe_b = _collect(values, offset_b, n_b)
    if fringe_a is None or fringe_b is None:
        return INVALID_RESULT
    return int(fringe_a == fringe_b)
