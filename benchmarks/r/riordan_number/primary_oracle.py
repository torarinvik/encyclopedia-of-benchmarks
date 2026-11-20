"""Exact recurrence for bounded Riordan numbers."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 30
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_VALID_INPUT_LENGTH = 1
MAX_RIORDAN_NUMBER = 439_742_222_071
MAX_RESULT_BOUND = MAX_RIORDAN_NUMBER
WORKSPACE_BYTES = 512
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n = values[0]
    return n if 0 <= n <= MAX_N else None


def _recurrence(n: int) -> int:
    values = [0] * (n + 1)
    values[0] = 1
    for size in range(2, n + 1):
        numerator = (size - 1) * (2 * values[size - 1] + 3 * values[size - 2])
        values[size] = numerator // (size + 1)
    return values[n]


def riordan_number(values: Sequence[int]) -> int:
    """Return R_n for a single-word valid input, or -1."""
    n = _parse(values, False, None)
    return INVALID_RESULT if n is None else _recurrence(n)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the exact Riordan number, or -1 for an invalid frame."""
    n = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if n is None else _recurrence(n)
