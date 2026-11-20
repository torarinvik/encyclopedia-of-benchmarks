"""Independent direct-submask reference for the subset zeta transform."""

from __future__ import annotations

from collections.abc import Sequence

MIN_BITS = 0
MAX_BITS = 6
MIN_VALUE = 0
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = 1 + (1 << MAX_BITS) + 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return -1
    bits = values[0]
    if not MIN_BITS <= bits <= MAX_BITS or len(values) != 1 + (1 << bits):
        return -1
    function = list(values[1:])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in function):
        return -1
    state_count = 1 << bits
    checksum = 0
    for mask in range(state_count):
        subset = mask
        subset_sum = 0
        while True:
            subset_sum += function[subset]
            if subset == 0:
                break
            subset = (subset - 1) & mask
        checksum += (mask + 1) * subset_sum
    return checksum
