"""Independent bounded oracle for the McGill expression-tree search."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LEAVES = 4
MAX_INPUT_LENGTH = 6
MAX_GOAL = 1_000_000_000
MAX_LEAF = 100
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the closest value selected by the source-ordered search."""
    if (
        not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    goal, count = values[0], values[1]
    if not 1 <= goal <= MAX_GOAL or not 1 <= count <= MAX_LEAVES or len(values) != count + 2:
        return -1
    leaves = list(values[2:])
    if any(not 1 <= value <= MAX_LEAF for value in leaves):
        return -1

    work = [0] * (2 * MAX_LEAVES)
    work[:count] = leaves
    current: list[tuple[int, int, int] | None] = [None] * MAX_LEAVES
    best = 0  # The C source's static initializer is observable for its edge case.
    stopped = False

    for value in leaves:
        if abs(value - goal) < abs(best - goal):
            best = value
    if best == goal:
        return best

    def visit(depth: int, depth_limit: int, used: int) -> None:
        nonlocal best, stopped
        if stopped:
            return
        if depth == depth_limit:
            candidate = work[count + depth - 1]
            if abs(candidate - goal) < abs(best - goal):
                best = candidate
                if best == goal:
                    stopped = True
            return

        for operation in range(1, 5):
            if stopped:
                return
            for first in range(count + depth):
                if stopped:
                    return
                if used & (1 << first):
                    continue
                for second in range(first):
                    if stopped:
                        return
                    if used & (1 << second):
                        continue
                    left, right = work[first], work[second]
                    if operation in (3, 4) and (left == 1 or right == 1):
                        continue
                    if left == 0 or right == 0:
                        continue
                    # Match the source's divisibility check before operand ordering.
                    if operation == 4 and left % right != 0:
                        continue
                    if operation in (2, 4) and left < right:
                        left, right = right, left
                    current[depth] = (left, right, operation)
                    if operation == 1:
                        result = left + right
                    elif operation == 2:
                        result = left - right
                    elif operation == 3:
                        result = left * right
                    else:
                        result = left // right
                    work[count + depth] = result
                    visit(depth + 1, depth_limit, used | (1 << first) | (1 << second))

    for depth_limit in range(1, count):
        visit(0, depth_limit, 0)
        if stopped:
            break
    return best
