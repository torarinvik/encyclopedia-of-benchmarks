"""One-row dynamic-programming reference for LCIS length."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
WORKSPACE_BYTES = 1024
MIN_VALUE = -16
MAX_VALUE = 16
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, m = values[0], values[1]
    if not 0 <= n <= MAX_N or not 0 <= m <= MAX_N or len(values) != 2 + n + m:
        return None
    first = list(values[2:2 + n])
    second = list(values[2 + n:])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in first + second):
        return None
    return first, second


def _lcis_length(first: list[int], second: list[int]) -> int:
    ending_at = [0] * len(second)
    for value in first:
        best_smaller = 0
        for j, other in enumerate(second):
            if value > other:
                best_smaller = max(best_smaller, ending_at[j])
            elif value == other:
                ending_at[j] = max(ending_at[j], best_smaller + 1)
    return max(ending_at, default=0)


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1
    return _lcis_length(*parsed)
