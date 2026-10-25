"""Independent contract oracle for LAME's bounded long-block MDCT helper."""

from __future__ import annotations

import math
from collections.abc import Sequence

INPUT_COUNT = 18
MAX_INPUT_LENGTH = 19
MAX_OUTPUT_ELEMENTS = 18
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-10
RELATIVE_TOLERANCE = 1e-10


def _valid(values: Sequence[int | float], input_is_null: bool = False, input_length: int | None = None) -> bool:
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
    return tuple(
        (4.0 / 36.0)
        * math.fsum(
            float(values[k]) * math.cos(
                math.pi * (2 * m + 1) * (4 * k + (38 if k < 9 else 74)) / 144.0
            )
            for k in range(INPUT_COUNT)
        )
        for m in range(INPUT_COUNT)
    )


def expected_output(
    values: Sequence[int | float],
    capacity: int = MAX_OUTPUT_ELEMENTS,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    if not _valid(values, input_is_null, input_length):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < MAX_OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, ()
    return MAX_OUTPUT_ELEMENTS, calculate(values)
