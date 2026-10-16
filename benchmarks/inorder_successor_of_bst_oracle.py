"""Independent oracle for the bounded BST inorder-successor contract."""

from __future__ import annotations

MAX_NODE_COUNT = 64
MAX_INPUT_LENGTH = MAX_NODE_COUNT + 3  # one extra key reaches the ABI as malformed input
INT32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
NO_SUCCESSOR = 0


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple))
            or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    count, target = values[:2]
    if not 0 <= count <= MAX_NODE_COUNT or not 1 <= target <= INT32_MAX:
        return INVALID_RESULT
    if len(values) != count + 2:
        return INVALID_RESULT
    keys = values[2:]
    if any(not 1 <= key <= INT32_MAX for key in keys) or len(set(keys)) != count:
        return INVALID_RESULT
    if target not in keys:
        return NO_SUCCESSOR
    successors = [key for key in keys if key > target]
    return min(successors) if successors else NO_SUCCESSOR
