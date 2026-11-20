"""Validated explicit-stack iterators for the same-fringe comparison."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "same_fringe_leaf_iterator"
MAX_NODES_PER_TREE = 15
MAX_TOTAL_NODES = 30
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_TOTAL_NODES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_LEAVES_PER_TREE = 8
MAX_RESULT = 1
MAX_WORKSPACE_BYTES = 1_024
WORKSPACE_BYTES = MAX_WORKSPACE_BYTES
INVALID_RESULT = -1


def _parse_frame(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None) -> tuple[int, int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    n_a, n_b = values[0], values[1]
    if not (1 <= n_a <= MAX_NODES_PER_TREE and 1 <= n_b <= MAX_NODES_PER_TREE):
        return None
    if n_a + n_b > MAX_TOTAL_NODES or len(values) != 2 + 3 * (n_a + n_b):
        return None
    return n_a, n_b, 2, 2 + 3 * n_a


def _valid_tree(values: Sequence[int], offset: int, node_count: int) -> bool:
    """Check full-tree shape, unique parents, root, reachability, and acyclicity."""
    visited = [False] * MAX_NODES_PER_TREE
    parents = [0] * MAX_NODES_PER_TREE
    stack = [0]
    reached = 0
    while stack:
        node = stack.pop()
        if not 0 <= node < node_count or visited[node]:
            return False
        visited[node] = True
        reached += 1
        base = offset + 3 * node
        left, right = values[base + 1], values[base + 2]
        if left == -1 and right == -1:
            continue
        if not (0 <= left < node_count and 0 <= right < node_count) or left == right:
            return False
        for child in (left, right):
            if child == 0:
                return False
            parents[child] += 1
            if parents[child] != 1:
                return False
        stack.append(right)
        stack.append(left)
    if reached != node_count or parents[0] != 0:
        return False
    return all(parents[node] == 1 for node in range(1, node_count))


def _next_leaf(values: Sequence[int], offset: int, stack: list[int]) -> int | None:
    """Return the next left-to-right leaf label, or None when exhausted."""
    while stack:
        node = stack.pop()
        base = offset + 3 * node
        left, right = values[base + 1], values[base + 2]
        if left == -1:
            return values[base]
        stack.append(right)
        stack.append(left)
    return None


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return 1 for equal ordered fringes, 0 for unequal, or -1 for invalid input."""
    frame = _parse_frame(values, input_is_null, input_length)
    if frame is None:
        return INVALID_RESULT
    n_a, n_b, offset_a, offset_b = frame
    if not _valid_tree(values, offset_a, n_a) or not _valid_tree(values, offset_b, n_b):
        return INVALID_RESULT

    stack_a = [0]
    stack_b = [0]
    while True:
        leaf_a = _next_leaf(values, offset_a, stack_a)
        leaf_b = _next_leaf(values, offset_b, stack_b)
        if leaf_a is None or leaf_b is None:
            return int(leaf_a is None and leaf_b is None)
        if leaf_a != leaf_b:
            return 0
