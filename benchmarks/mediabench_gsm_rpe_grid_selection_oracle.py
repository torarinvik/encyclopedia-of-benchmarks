"""Independent contract model for the GSM RPE grid-selection kernel."""

from __future__ import annotations

from collections.abc import Sequence

INPUT_COUNT = 40
MAX_INPUT_LENGTH = 41
MAX_OUTPUT_BYTES = 14 * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_SAMPLE = -32768
MAX_SAMPLE = 32767


def calculate(values: Sequence[int]) -> tuple[int, ...]:
    def shifted(sample: int) -> int:
        return sample // 4

    scores = [
        2 * sum(shifted(values[grid + 3 * index]) ** 2 for index in range(13))
        for grid in range(4)
    ]
    grid = max(range(4), key=lambda item: (scores[item], -item))
    return (grid, *(values[grid + 3 * index] for index in range(13)))


def _valid(values: Sequence[int], input_is_null: bool = False, input_length: int | None = None) -> bool:
    if input_is_null or not isinstance(values, (tuple, list)):
        return False
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != INPUT_COUNT or len(values) != INPUT_COUNT:
        return False
    return all(type(value) is int and MIN_SAMPLE <= value <= MAX_SAMPLE for value in values)


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
