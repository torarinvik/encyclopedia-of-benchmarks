"""Independent oracle for the bounded binary-search-tree ceiling contract."""

from __future__ import annotations

MAX_NODE_COUNT = 127
VALUE_MIN, VALUE_MAX = -1_000_000, 1_000_000
INVALID_RESULT = -(2**63) + 1
NO_CEIL_RESULT = -(2**63)
MAX_INPUT_LENGTH = 3 + 3 * MAX_NODE_COUNT


def expected_result(values: list[int]) -> int:
    """Return the least node value >= key, or an explicit sentinel."""
    if (not isinstance(values, list) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    node_count, root_index, key = values[:3]
    if not 0 <= node_count <= MAX_NODE_COUNT or not VALUE_MIN <= key <= VALUE_MAX:
        return INVALID_RESULT
    if len(values) != 3 + 3 * node_count:
        return INVALID_RESULT
    if node_count == 0:
        return NO_CEIL_RESULT if root_index == -1 else INVALID_RESULT
    if not 0 <= root_index < node_count:
        return INVALID_RESULT

    nodes: list[tuple[int, int, int]] = []
    parents = [0] * node_count
    for offset in range(3, len(values), 3):
        value, left, right = values[offset : offset + 3]
        if not VALUE_MIN <= value <= VALUE_MAX:
            return INVALID_RESULT
        if any(child < -1 or child >= node_count for child in (left, right)):
            return INVALID_RESULT
        for child in (left, right):
            if child >= 0:
                parents[child] += 1
        nodes.append((value, left, right))
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(node_count) if index != root_index):
        return INVALID_RESULT

    stack = [(root_index, None, None)]
    seen: set[int] = set()
    while stack:
        index, lower, upper = stack.pop()
        if index in seen:
            return INVALID_RESULT
        seen.add(index)
        value, left, right = nodes[index]
        if (lower is not None and value <= lower) or (upper is not None and value >= upper):
            return INVALID_RESULT
        if left >= 0:
            stack.append((left, lower, value))
        if right >= 0:
            stack.append((right, value, upper))
    if len(seen) != node_count:
        return INVALID_RESULT

    candidates = [value for value, _, _ in nodes if value >= key]
    return min(candidates) if candidates else NO_CEIL_RESULT
