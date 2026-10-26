"""Independent contract model for GSM RPE grid positioning."""

from __future__ import annotations

from collections.abc import Sequence

INPUT_COUNT = 14
MAX_INPUT_LENGTH = 15
OUTPUT_COUNT = 40
MAX_OUTPUT_BYTES = 2 * OUTPUT_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_WORD = -32768
MAX_WORD = 32767


def calculate(values: Sequence[int]) -> tuple[int, ...]:
    """Scatter thirteen decoded RPE values at the selected three-step phase."""
    grid = values[0]
    result = [0] * OUTPUT_COUNT
    for index, sample in enumerate(values[1:]):
        result[grid + 3 * index] = sample
    return tuple(result)


def _valid(values: Sequence[int], input_is_null: bool = False,
           input_length: int | None = None) -> bool:
    if type(input_is_null) is not bool or input_is_null:
        return False
    if not isinstance(values, (tuple, list)):
        return False
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != INPUT_COUNT or len(values) != INPUT_COUNT:
        return False
    if type(values[0]) is not int or not 0 <= values[0] <= 3:
        return False
    return all(type(value) is int and MIN_WORD <= value <= MAX_WORD for value in values[1:])


def expected_output(
    values: Sequence[int],
    capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, tuple[int, ...]]:
    if not _valid(values, input_is_null, input_length):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, ()
    return MAX_OUTPUT_BYTES, calculate(values)
