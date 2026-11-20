"""Estimator-difference reference for the a=1/2 Morris counter variant."""

from __future__ import annotations

MAX_UPDATES = 30
DRAW_SPACE = 3 ** MAX_UPDATES
MAX_VALID_INPUT_LENGTH = 1 + MAX_UPDATES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16


def _i64(value: object) -> bool:
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _estimate(state: int) -> int:
    return (3**state - 1) // 2


def _replay(draws: list[int] | tuple[int, ...]) -> tuple[int, int]:
    state = 0
    for draw in draws:
        # The generalized Morris rule uses the reciprocal spacing between
        # adjacent decoded counts. Compare as an exact integer inequality.
        count_gap = _estimate(state + 1) - _estimate(state)
        if draw * count_gap < DRAW_SPACE:
            state += 1
    return state, _estimate(state)


def expected_output(
    values,
    capacity=None,
    output_is_null=False,
    input_is_null=False,
    input_length=None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    length = len(values)
    if not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _i64(word) for word in values):
        return -1, b""

    updates_value = values[0]
    if not 0 <= updates_value <= MAX_UPDATES:
        return -1, b""
    if length != 1 + updates_value:
        return -1, b""
    draws = values[1:]
    if any(not 0 <= draw < DRAW_SPACE for draw in draws):
        return -1, b""

    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    state, estimate = _replay(draws)
    output = state.to_bytes(8, "little", signed=True)
    output += estimate.to_bytes(8, "little", signed=True)
    return MAX_OUTPUT_BYTES, output
