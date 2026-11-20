"""Primary two-character lookahead reference for Berry–Ravindran search."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 256
MIN_PATTERN_LENGTH = 1
MAX_PATTERN_LENGTH = 16
ALPHABET_SIZE = 16
SENTINEL = 16
MAX_VALID_INPUT_LENGTH = 274
MAX_PARSEABLE_INPUT_LENGTH = 274
INVALID_RESULT = -2
NOT_FOUND = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Return the earliest hit using the pair-lookahead shift table."""
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
    if (not 0 <= n <= MAX_TEXT_LENGTH
            or not MIN_PATTERN_LENGTH <= m <= MAX_PATTERN_LENGTH
            or len(values) != 2 + n + m):
        return INVALID_RESULT
    text = values[2:2 + n]
    pattern = values[2 + n:]
    if any(byte < 0 or byte >= ALPHABET_SIZE for byte in text + pattern):
        return INVALID_RESULT
    if m > n:
        return NOT_FOUND

    # One extra symbol represents the virtual end marker without colliding
    # with any byte in the benchmark alphabet.
    side = ALPHABET_SIZE + 1
    pair_shift = [[m + 2] * side for _ in range(side)]
    for first in range(side):
        pair_shift[first][pattern[0]] = m + 1
    for index in range(m - 1):
        pair_shift[pattern[index]][pattern[index + 1]] = m - index
    for second in range(side):
        pair_shift[pattern[-1]][second] = 1

    start = 0
    last_start = n - m
    while start <= last_start:
        offset = 0
        while offset < m and text[start + offset] == pattern[offset]:
            offset += 1
        if offset == m:
            return start
        first_index = start + m
        if first_index >= n:
            break
        second_index = first_index + 1
        first = text[first_index]
        second = text[second_index] if second_index < n else SENTINEL
        start += pair_shift[first][second]
    return NOT_FOUND
