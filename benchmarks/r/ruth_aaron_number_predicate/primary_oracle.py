"""Trial-division reference for the repeated-factor Ruth-Aaron predicate."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 100_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_FACTOR_SUM = MAX_N + 1
WORKSPACE_BYTES = 1_048_576
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
    n = values[0]
    return n if 1 <= n <= MAX_N else None


def _prime_factor_sum_counted(value: int) -> int:
    total = 0
    divisor = 2
    while divisor <= value // divisor:
        while value % divisor == 0:
            total += divisor
            value //= divisor
        divisor += 1
    if value > 1:
        total += value
    return total


def _is_ruth_aaron(n: int) -> int:
    return int(_prime_factor_sum_counted(n) == _prime_factor_sum_counted(n + 1))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return 1 for a repeated-factor Ruth-Aaron number, 0 otherwise, -1 invalid."""
    n = _parse(values, input_is_null, input_length)
    return -1 if n is None else _is_ruth_aaron(n)
