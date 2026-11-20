"""Independent direct checksum reference for an Elias–Fano sequence."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VALUES = 1
MAX_VALUES = 32
MAX_UPPER_BOUND = 1_000_000
MAX_INPUT_LENGTH = MAX_VALUES + 3
MAX_RESULT = MAX_VALUES * (MAX_VALUES + 1) // 2 * MAX_UPPER_BOUND


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return -1
    count, upper_bound = values[:2]
    if (not MIN_VALUES <= count <= MAX_VALUES
            or not 0 <= upper_bound <= MAX_UPPER_BOUND
            or count > upper_bound + 1
            or len(values) != count + 2):
        return -1
    sequence = values[2:]
    if (any(not 0 <= value <= upper_bound for value in sequence)
            or any(sequence[index] > sequence[index + 1]
                   for index in range(count - 1))):
        return -1
    return sum((index + 1) * value for index, value in enumerate(sequence))
