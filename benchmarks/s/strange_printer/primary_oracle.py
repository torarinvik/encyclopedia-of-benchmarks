"""Cubic interval recurrence for the minimum strange-printer turn count."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 8
MAX_SYMBOL = 2
MAX_VALID_INPUT_LENGTH = MAX_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_WORKSPACE_BYTES = 81 * 8
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    length = values[0]
    if not 0 <= length <= MAX_LENGTH or len(values) != length + 1:
        return None
    symbols = tuple(values[1:])
    if any(symbol < 0 or symbol > MAX_SYMBOL for symbol in symbols):
        return None
    return symbols


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    symbols = _parse(values, input_is_null, input_length)
    if symbols is None:
        return INVALID_RESULT
    length = len(symbols)
    if length == 0:
        return 0

    dp = [[0] * length for _ in range(length)]
    for left in range(length - 1, -1, -1):
        dp[left][left] = 1
        for right in range(left + 1, length):
            best = dp[left + 1][right] + 1
            for merge in range(left + 1, right + 1):
                if symbols[left] == symbols[merge]:
                    middle = dp[left + 1][merge - 1] if merge > left + 1 else 0
                    best = min(best, middle + dp[merge][right])
            dp[left][right] = best
    return dp[0][length - 1]
