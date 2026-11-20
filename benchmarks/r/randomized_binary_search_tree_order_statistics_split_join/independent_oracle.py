"""Independent sorted-list reference for RBST operation-trace semantics."""

from __future__ import annotations

from bisect import bisect_left
from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[int], list[tuple[int, int, int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= 164:
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return None
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return None
    n, q, seed = values[:3]
    if not 0 <= n <= 32 or not 0 <= q <= 32 or not 0 <= seed <= 0xFFFFFFFF:
        return None
    if len(values) != 3 + n + 4 * q:
        return None
    initial = list(values[3:3 + n])
    if any(not 0 <= key <= 1000 for key in initial):
        return None
    if any(initial[index - 1] >= initial[index] for index in range(1, len(initial))):
        return None

    operations = []
    start = 3 + n
    for index in range(q):
        op, first, second, third = values[start + 4 * index:start + 4 * index + 4]
        if op in (0, 1):
            valid = first in (0, 1) and 0 <= second <= 1000 and third == 0
        elif op == 2:
            valid = first in (0, 1) and 1 <= second <= 65 and third == 0
        elif op == 3:
            valid = first in (0, 1) and second in (0, 1) and first != second and 0 <= third <= 1001
        elif op == 4:
            valid = first in (0, 1) and second in (0, 1) and first != second and third == 0
        else:
            valid = False
        if not valid:
            return None
        operations.append((op, first, second, third))
    return initial, operations


def _trace(initial: list[int], operations: list[tuple[int, int, int, int]]) -> int:
    trees = [initial.copy(), []]
    checksum = 0
    query_number = 0
    for op, first, second, third in operations:
        if op == 0:
            tree = trees[first]
            at = bisect_left(tree, second)
            if at == len(tree) or tree[at] != second:
                tree.insert(at, second)
        elif op == 1:
            tree = trees[first]
            at = bisect_left(tree, second)
            if at < len(tree) and tree[at] == second:
                tree.pop(at)
        elif op == 2:
            query_number += 1
            tree = trees[first]
            answer = tree[second - 1] if second <= len(tree) else -1
            checksum += query_number * (answer + 1)
        elif op == 3:
            if trees[second]:
                return -1
            source = trees[first]
            boundary = bisect_left(source, third)
            trees[first] = source[:boundary]
            trees[second] = source[boundary:]
        else:
            left = trees[first]
            right = trees[second]
            if left and right and left[-1] >= right[0]:
                return -1
            left.extend(right)
            trees[second] = []
    return checksum


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1
    initial, operations = parsed
    return _trace(initial, operations)
