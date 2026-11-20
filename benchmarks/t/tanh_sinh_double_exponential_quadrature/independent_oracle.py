"""Closed-form integral oracle, independent of the finite transformed sum."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_ELEMENTS = 1
WORKSPACE_ELEMENTS = 1
WORKSPACE_BYTES = 8


def _valid_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _decode(values: Sequence[int | float], input_is_null: bool,
            input_length: int) -> tuple[int, int] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values) or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(not _valid_number(value) for value in values)):
        return None
    raw_id, raw_p = float(values[0]), float(values[1])
    if (input_length != 2 or not raw_id.is_integer() or not raw_p.is_integer()
            or not 0.0 <= raw_id <= 3.0 or not 2.0 <= raw_p <= 4.0):
        return None
    return int(raw_id), int(raw_p)


def _analytic(function_id: int) -> float:
    if function_id == 0:
        return 2.0
    if function_id == 1:
        return 2.0 / 3.0
    if function_id == 2:
        return math.pi
    return 2.0 * math.sqrt(2.0)


def expected_output(values: Sequence[int | float], capacity: int | None = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    actual_length = (len(values) if input_length is None
                     and isinstance(values, (list, tuple)) else input_length)
    if actual_length is None:
        return INVALID_RESULT, ()
    decoded = _decode(values, input_is_null, actual_length)
    if decoded is None:
        return INVALID_RESULT, ()
    if type(output_is_null) is not bool or (capacity is not None and
            (type(capacity) is not int or capacity < 0)):
        return INVALID_RESULT, ()
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_ELEMENTS):
        return OUTPUT_ERROR, ()
    return 1, (_analytic(decoded[0]),)
