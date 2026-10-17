"""Independent bounded oracle for single-heap subtraction Grundy numbers."""

from __future__ import annotations

MAX_POSITION = 64
MAX_MOVE_COUNT = 32
MAX_MOVE_SIZE = 32
MAX_INPUT_LENGTH = 2 + MAX_MOVE_COUNT
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int]) -> int:
    if not values or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return INVALID_RESULT

    position, move_count = values[0], values[1] if len(values) > 1 else -1
    if position < 0 or position > MAX_POSITION:
        return INVALID_RESULT
    if move_count < 0 or move_count > MAX_MOVE_COUNT or len(values) != 2 + move_count:
        return INVALID_RESULT
    moves = values[2:]
    if any(move < 1 or move > MAX_MOVE_SIZE for move in moves):
        return INVALID_RESULT

    memo = [-1] * (position + 1)

    def grundy(current: int) -> int:
        if memo[current] != -1:
            return memo[current]
        if current == 0:
            memo[0] = 0
            return 0

        reachable = {grundy(current - move) for move in moves if move <= current}
        mex = 0
        while mex in reachable:
            mex += 1
        memo[current] = mex
        return mex

    return grundy(position)
