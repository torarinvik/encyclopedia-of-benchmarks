"""Unbounded-state BFS reference for the bounded race-car target profile."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_TARGET = 127
MAX_RESULT_UPPER_BOUND = 379
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 512


def _valid_target(values: Sequence[int] | None, input_is_null: bool,
                  input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1:
        return None
    target = values[0]
    return target if 0 <= target <= MAX_TARGET else None


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    target = _valid_target(values, input_is_null, input_length)
    if target is None:
        return -1
    if target == 0:
        return 0

    pending = deque([(0, 1, 0)])
    visited = {(0, 1)}
    while pending:
        position, speed, commands = pending.popleft()
        if position == target:
            return commands
        transitions = (
            (position + speed, speed * 2),
            (position, -1 if speed > 0 else 1),
        )
        for state in transitions:
            if state not in visited:
                visited.add(state)
                pending.append((state[0], state[1], commands + 1))
    return -1
