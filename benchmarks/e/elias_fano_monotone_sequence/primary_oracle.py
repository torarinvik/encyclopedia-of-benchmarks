"""Bounded Elias–Fano encode-and-access reference."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VALUES = 1
MAX_VALUES = 32
MIN_UPPER_BOUND = 0
MAX_UPPER_BOUND = 1_000_000
MAX_VALID_INPUT_LENGTH = MAX_VALUES + 2
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_VALUES * (MAX_VALUES + 1) // 2 * MAX_UPPER_BOUND
MAX_HIGH_BITS = 3 * MAX_VALUES


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not MIN_VALUES + 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    count, upper_bound = values[:2]
    if (not MIN_VALUES <= count <= MAX_VALUES
            or not MIN_UPPER_BOUND <= upper_bound <= MAX_UPPER_BOUND
            or count > upper_bound + 1
            or len(values) != count + 2):
        return None
    sequence = list(values[2:])
    if (any(not 0 <= value <= upper_bound for value in sequence)
            or any(sequence[index] > sequence[index + 1]
                   for index in range(count - 1))):
        return None
    return count, upper_bound, sequence


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    count, upper_bound, sequence = parsed

    low_width = 0
    while count << (low_width + 1) <= upper_bound + 1:
        low_width += 1
    low_mask = (1 << low_width) - 1
    low_parts = [value & low_mask for value in sequence]
    high_length = (upper_bound >> low_width) + count
    if high_length > MAX_HIGH_BITS:
        return -1
    high_bits = [0] * high_length
    for index, value in enumerate(sequence):
        position = (value >> low_width) + index
        if position >= high_length:
            return -1
        high_bits[position] = 1

    checksum = 0
    item_index = 0
    for position, bit in enumerate(high_bits):
        if bit:
            high_part = position - item_index
            decoded = (high_part << low_width) | low_parts[item_index]
            checksum += (item_index + 1) * decoded
            item_index += 1
    return checksum if item_index == count else -1
