"""Independent binary64 oracle for LAME's bounded short-block MDCT helper."""

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
PI = math.pi
ENWINDOW_MAX = 0.030526638  # pinned newmdct.c: enwindow[256 - 8]


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
        if not math.isfinite(number) or not -32768.0 <= number <= 32768.0:
            return False
    return True


def calculate(values: Sequence[int | float]) -> tuple[float, ...]:
    # Recreate the source's short cosine table from its initialization formula.
    coefficients = [[0.0] * 6 for _ in range(6)]
    scale = 4.0 / 12.0
    for i in range(3):
        window_factor = math.cos(PI / 12.0 * (i + 0.5)) * ENWINDOW_MAX / 32768.0 * scale
        for m in range(6):
            coefficients[m][i] = window_factor * math.cos((PI / 48.0) * (2 * m + 1) * (4 * i + 14))
            coefficients[m][i + 3] = window_factor * math.cos((PI / 48.0) * (2 * m + 1) * (4 * i + 38))

    staged = [0.0] * MAX_OUTPUT_ELEMENTS
    for m in range(5, -1, -1):
        for window in range(2, -1, -1):
            base = 6 * window
            total = coefficients[m][0] * float(values[base])
            for coefficient in range(1, 6):
                total += coefficients[m][coefficient] * float(values[base + coefficient])
            staged[3 * m + window] = total
    return tuple(staged)


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, ()
    if not _valid(values, input_is_null, input_length):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < MAX_OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, ()
    return MAX_OUTPUT_ELEMENTS, calculate(values)
