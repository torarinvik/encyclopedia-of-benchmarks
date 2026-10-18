"""Oracle for the bounded forward Fisher–Yates shuffle workload."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_LENGTH = 0
MAX_LENGTH = 256
MIN_VALUE = -(1 << 31)
MAX_VALUE = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = 1 + MAX_LENGTH + max(MAX_LENGTH - 1, 0)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _exact_integer(value: int | float) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


def _decode_input(values: Sequence[float] | None):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None

    count = _exact_integer(values[0])
    if count is None or not MIN_LENGTH <= count <= MAX_LENGTH:
        return None
    offset_count = max(count - 1, 0)
    if len(values) != 1 + count + offset_count:
        return None

    items = [_exact_integer(value) for value in values[1:1 + count]]
    if any(value is None or not MIN_VALUE <= value <= MAX_VALUE for value in items):
        return None

    offsets = [_exact_integer(value) for value in values[1 + count:]]
    if len(offsets) != offset_count:
        return None
    for index, offset in enumerate(offsets):
        if offset is None or not 0 <= offset <= count - 1 - index:
            return None
    return count, items, offsets


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return the shuffled sequence, or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    count, items, offsets = decoded
    for index, offset in enumerate(offsets):
        other = index + offset
        items[index], items[other] = items[other], items[index]

    if output_is_null or (output_capacity is not None and output_capacity < count):
        return OUTPUT_ERROR, []
    return count, [float(value) for value in items]
