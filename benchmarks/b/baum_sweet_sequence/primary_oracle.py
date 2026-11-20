"""Per-index parity automaton for OEIS A086747."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COUNT = 63
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def _term_automaton(number: int) -> int:
    if number == 0:
        return 0
    mask = 1
    while mask <= number // 2:
        mask *= 2
    odd_zero_run = False
    while mask:
        if number & mask:
            if odd_zero_run:
                return 0
            odd_zero_run = False
        else:
            odd_zero_run = not odd_zero_run
        mask //= 2
    return int(not odd_zero_run)


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) != 1
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_COUNT:
        return INVALID_RESULT
    packed = 0
    for number in range(count):
        if _term_automaton(number):
            packed |= 1 << number
    return packed
