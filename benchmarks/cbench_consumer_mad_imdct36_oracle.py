"""Independent binary64 oracle for the bounded libmad IMDCT36 profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

INPUT_COUNT = 18
MAX_INPUT_LENGTH = 19
MAX_OUTPUT_ELEMENTS = 36
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-11
RELATIVE_TOLERANCE = 1e-11


def _valid(values: Sequence[int | float], input_is_null: bool = False,
           input_length: int | None = None) -> bool:
    if input_is_null or not isinstance(values, (tuple, list)):
        return False
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != INPUT_COUNT or len(values) != INPUT_COUNT:
        return False
    for value in values:
        if type(value) not in (int, float):
            return False
        number = float(value)
        if not math.isfinite(number) or number < -16.0 or number > 16.0:
            return False
    return True


def calculate(values: Sequence[int | float]) -> tuple[float, ...]:
    # Keep the contract's ascending-k, left-to-right accumulation order.
    output: list[float] = []
    for n in range(MAX_OUTPUT_ELEMENTS):
        total = 0.0
        for k in range(INPUT_COUNT):
            angle = math.pi * (2 * n + 19) * (2 * k + 1) / 72.0
            total += float(values[k]) * math.cos(angle)
        output.append(total)
    return tuple(output)


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if not _valid(values, input_is_null, input_length):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < MAX_OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, ()
    return MAX_OUTPUT_ELEMENTS, calculate(values)
