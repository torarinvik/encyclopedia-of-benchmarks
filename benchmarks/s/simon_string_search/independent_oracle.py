"""Independent all-window reference; it does not build or traverse an automaton."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    INVALID_RESULT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN_LENGTH,
    MAX_TEXT_LENGTH,
)


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if length is None:
        declared = len(values) if isinstance(values, (tuple, list)) else -1
    elif type(length) is int and length >= 0:
        declared = length
    else:
        return INVALID_RESULT
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH or declared != len(values)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if (not 0 <= n <= MAX_TEXT_LENGTH or not 1 <= m <= MAX_PATTERN_LENGTH
            or len(values) != 2 + n + m):
        return INVALID_RESULT
    text = values[2:2 + n]
    pattern = values[2 + n:]
    if any(symbol < 0 or symbol > 15 for symbol in text + pattern):
        return INVALID_RESULT
    matches = 0
    for start in range(n - m + 1):
        same = True
        for offset in range(m):
            if text[start + offset] != pattern[offset]:
                same = False
                break
        if same:
            matches += 1
    return matches
