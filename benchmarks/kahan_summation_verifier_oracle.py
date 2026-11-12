"""Independent exact-rational model of each rounded Kahan recurrence step."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT_LENGTH = 256
MAX_ABS_VALUE = 1.0e100
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _read_frame(values: Sequence[float] | None, input_length: int | None,
                input_is_null: bool) -> tuple[float, ...] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if len(values) > MAX_INPUT_LENGTH:
        return None
    converted: list[float] = []
    for item in values:
        if type(item) not in (int, float):
            return None
        try:
            value = float(item)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(value) or not -MAX_ABS_VALUE <= value <= MAX_ABS_VALUE:
            return None
        converted.append(value)
    return tuple(converted)


def _rounded(exact: Fraction) -> float:
    """Round an exact rational to the nearest binary64 value, ties to even."""
    return float(exact)


def _independent_kahan(values: Sequence[float]) -> float:
    total = 0.0
    correction = 0.0
    for value in values:
        adjusted = _rounded(Fraction.from_float(value) - Fraction.from_float(correction))
        next_total = _rounded(Fraction.from_float(total) + Fraction.from_float(adjusted))
        difference = _rounded(Fraction.from_float(next_total) - Fraction.from_float(total))
        correction = _rounded(Fraction.from_float(difference) - Fraction.from_float(adjusted))
        total = next_total
    return total


def expected_abi(values: Sequence[float] | None, output_capacity: int | None = None,
                 output_is_null: bool = False, input_is_null: bool = False,
                 input_length: int | None = None) -> tuple[int, list[float]]:
    if type(output_is_null) is not bool:
        return INVALID_RESULT, []
    frame = _read_frame(values, input_length, input_is_null)
    if frame is None:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < 1):
        return OUTPUT_ERROR, []
    return 1, [_independent_kahan(frame)]


def verify_result(values: Sequence[float] | None, result: int, output: Sequence[float],
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False,
                  input_length: int | None = None) -> bool:
    expected_result, expected_values = expected_abi(
        values, output_capacity, output_is_null, input_is_null, input_length
    )
    if type(result) is not int or result != expected_result:
        return False
    if expected_result < 0:
        return not output
    if not isinstance(output, (list, tuple)) or len(output) != len(expected_values):
        return False
    return all(
        type(actual) in (float, int)
        and struct.pack("=d", float(actual)) == struct.pack("=d", expected)
        for actual, expected in zip(output, expected_values)
    )
