"""Primary bounded oracle for ordered binary64 Kahan summation."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_INPUT_LENGTH = 256
MAX_ABS_VALUE = 1.0e100
MAX_OUTPUT_ELEMENTS = 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _read_input(values: Sequence[float] | None, input_length: int | None,
                input_is_null: bool) -> tuple[float, ...] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 0 <= length <= MAX_INPUT_LENGTH:
        return None
    parsed: list[float] = []
    for item in values:
        if type(item) not in (int, float):
            return None
        try:
            value = float(item)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(value) or abs(value) > MAX_ABS_VALUE:
            return None
        parsed.append(value)
    return tuple(parsed)


def _kahan(values: Sequence[float]) -> float:
    total = 0.0
    correction = 0.0
    for value in values:
        adjusted = value - correction
        next_total = total + adjusted
        correction = (next_total - total) - adjusted
        total = next_total
    return total


def expected_output(values: Sequence[float] | None) -> list[float] | None:
    """Return the one-element result, or None for an invalid input frame."""
    parsed = _read_input(values, None, False)
    if parsed is None:
        return None
    return [_kahan(parsed)]


def expected_abi(values: Sequence[float] | None, output_capacity: int | None = None,
                 output_is_null: bool = False, input_is_null: bool = False,
                 input_length: int | None = None) -> tuple[int, list[float]]:
    """Return output count and values for the float64-slice ABI contract."""
    if type(output_is_null) is not bool:
        return INVALID_RESULT, []
    parsed = _read_input(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < 1):
        return OUTPUT_ERROR, []
    return 1, [_kahan(parsed)]
