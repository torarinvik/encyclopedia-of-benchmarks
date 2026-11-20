"""Direct trial-factorization reference for the Euclid–Mullin sequence."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_TERM = 6_221_671
MAX_CANDIDATE = 6_221_671
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 64
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    index = values[0]
    return index if 1 <= index <= MAX_N else None


def _least_factor_by_trial_division(value: int) -> int:
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return divisor
        divisor += 1
    return value


def _term(index: int) -> int:
    product = 1
    term = 1
    for _ in range(index):
        term = _least_factor_by_trial_division(product + 1)
        product *= term
    return term


def euclid_mullin_sequence(values: Sequence[int]) -> int:
    """Return the indexed term for a one-word frame, or -1 if invalid."""
    index = _parse(values, False, None)
    return -1 if index is None else _term(index)


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the exact bounded term, or -1 for an invalid frame."""
    index = _parse(values, input_is_null, input_length)
    return -1 if index is None else _term(index)
