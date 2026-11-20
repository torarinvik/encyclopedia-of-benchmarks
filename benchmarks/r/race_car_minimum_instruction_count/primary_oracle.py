"""Run-length dynamic program for the bounded race-car profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TARGET = 127
MAX_RESULT_UPPER_BOUND = 379
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 512


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not 0 <= values[0] <= MAX_TARGET:
        return None
    return values[0]


def _minimum_commands(target: int) -> int:
    distance = [0] * (target + 1)
    for position in range(1, target + 1):
        run = position.bit_length()
        upper = (1 << run) - 1
        if position == upper:
            distance[position] = run
            continue

        best = run + 1 + distance[upper - position]
        lower = (1 << (run - 1)) - 1
        for backward_run in range(run - 1):
            backward_distance = (1 << backward_run) - 1
            remaining = position - (lower - backward_distance)
            candidate = run + backward_run + 1 + distance[remaining]
            if candidate < best:
                best = candidate
        distance[position] = best
    return distance[target]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    target = _decode(values, input_is_null, input_length)
    if target is None:
        return -1
    return _minimum_commands(target)
