"""Closed-form distance for a knight on the unbounded integer lattice."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COORDINATE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_RESULT = 666_666_668
MAX_WORKSPACE_BYTES = 0
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    dx, dy = values
    if abs(dx) > MAX_COORDINATE or abs(dy) > MAX_COORDINATE:
        return None
    return dx, dy


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    displacement = _parse(values, input_is_null, input_length)
    if displacement is None:
        return INVALID_RESULT
    dx, dy = displacement
    large = max(abs(dx), abs(dy))
    small = min(abs(dx), abs(dy))
    if large == 1 and small == 0:
        return 3
    if large == 2 and small == 2:
        return 4

    lower_bound = max((large + 1) // 2, (large + small + 2) // 3)
    parity_correction = (large + small - lower_bound) & 1
    return lower_bound + parity_correction
