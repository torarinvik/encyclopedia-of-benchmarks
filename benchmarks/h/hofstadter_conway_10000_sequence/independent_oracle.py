"""Demand-driven dependency-stack reference for the same recurrence."""
from __future__ import annotations

MAX_INDEX = 8192


def sequence_term(index: int) -> int | None:
    if type(index) is not int or not 1 <= index <= MAX_INDEX:
        return None
    memo = {1: 1, 2: 1}
    stack: list[tuple[int, int]] = [(index, 0)]
    while stack:
        current, phase = stack.pop()
        if current in memo:
            continue
        if not 3 <= current <= index:
            return None
        if phase == 0:
            stack.append((current, 1))
            if current - 1 not in memo:
                stack.append((current - 1, 0))
            continue
        if phase == 1:
            previous = memo.get(current - 1)
            if previous is None or not 1 <= previous < current:
                return None
            other = current - previous
            if not 1 <= other < current:
                return None
            stack.append((current, 2))
            if other not in memo:
                stack.append((other, 0))
            if previous not in memo:
                stack.append((previous, 0))
            continue
        previous = memo.get(current - 1)
        if previous is None:
            return None
        other = current - previous
        left_value = memo.get(previous)
        right_value = memo.get(other)
        if left_value is None or right_value is None:
            return None
        memo[current] = left_value + right_value
    return memo.get(index)


def expected_result(values, *, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if (values is None or input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= 2):
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return -1
    if (input_length is not None
            and (type(input_length) is not int or not 1 <= input_length <= 2)):
        return -1
    if (len(values) != 1 or (input_length is not None and input_length != 1)
            or not 2 <= values[0] <= MAX_INDEX):
        return -1
    result = sequence_term(values[0])
    return -1 if result is None else result
