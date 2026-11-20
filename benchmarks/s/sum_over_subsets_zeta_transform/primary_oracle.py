"""Bounded subset zeta transform reference."""

from __future__ import annotations

from collections.abc import Sequence

MIN_BITS = 0
MAX_BITS = 6
MIN_VALUE = 0
MAX_VALUE = 1_000_000
MAX_VALID_INPUT_LENGTH = 1 + (1 << MAX_BITS)
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_VALUE * (1 << (2 * MAX_BITS)) * ((1 << MAX_BITS) + 1) // 2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    bits = values[0]
    if not MIN_BITS <= bits <= MAX_BITS or len(values) != 1 + (1 << bits):
        return None
    function = list(values[1:])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in function):
        return None
    return bits, function


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    bits, transformed = parsed
    state_count = 1 << bits
    for bit_index in range(bits):
        bit = 1 << bit_index
        for mask in range(state_count):
            if mask & bit:
                transformed[mask] += transformed[mask ^ bit]
    return sum((mask + 1) * transformed[mask] for mask in range(state_count))
