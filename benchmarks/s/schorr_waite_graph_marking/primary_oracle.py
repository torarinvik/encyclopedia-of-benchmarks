"""Explicit-stack reachability reference for the Schorr-Waite contract."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_NODES = 1
MAX_NODES = 32
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
WORKSPACE_BYTES = 1024


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2 or not MIN_NODES <= values[0] <= MAX_NODES:
        return None
    node_count, root = values[:2]
    if not 0 <= root < node_count or len(values) != 2 + 2 * node_count:
        return None
    left = []
    right = []
    for node in range(node_count):
        left_child, right_child = values[2 + 2 * node:4 + 2 * node]
        if any(child != -1 and not 0 <= child < node_count
               for child in (left_child, right_child)):
            return None
        left.append(left_child)
        right.append(right_child)
    return node_count, root, left, right


def reachable_bitset(node_count: int, root: int,
                     left: list[int], right: list[int]) -> int:
    marked = [False] * node_count
    stack = [root]
    while stack:
        node = stack.pop()
        if marked[node]:
            continue
        marked[node] = True
        if left[node] != -1:
            stack.append(left[node])
        if right[node] != -1:
            stack.append(right[node])
    return sum((1 << node) for node, is_marked in enumerate(marked) if is_marked)


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    node_count, root, left, right = decoded
    return reachable_bitset(node_count, root, left, right)
