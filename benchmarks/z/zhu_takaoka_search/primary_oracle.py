"""Zhu–Takaoka pair bad-character and strong good-suffix reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 256
MIN_PATTERN_LENGTH = 2
MAX_PATTERN_LENGTH = 16
ALPHABET_SIZE = 16
MAX_VALID_INPUT_LENGTH = 274
MAX_PARSEABLE_INPUT_LENGTH = 274
INVALID_RESULT = -2
NOT_FOUND = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _good_suffix_shifts(pattern: Sequence[int]) -> list[int]:
    """Build exact strong-good-suffix shifts by bounded candidate checking."""
    length = len(pattern)
    shifts = [length] * length
    for mismatch in range(length):
        for shift in range(1, length + 1):
            first_known = max(mismatch + 1, shift)
            if any(pattern[position] != pattern[position - shift]
                   for position in range(first_known, length)):
                continue
            if (mismatch + 1 < length and shift <= mismatch
                    and pattern[mismatch - shift] == pattern[mismatch]):
                continue
            shifts[mismatch] = shift
            break
    full_shift = length
    for shift in range(1, length + 1):
        if all(pattern[position] == pattern[position - shift]
               for position in range(shift, length)):
            full_shift = shift
            break
    return shifts + [full_shift]


def _search(text: Sequence[int], pattern: Sequence[int]) -> int:
    text_length, pattern_length = len(text), len(pattern)
    if pattern_length > text_length:
        return NOT_FOUND

    pair_shift = [[pattern_length] * ALPHABET_SIZE
                  for _ in range(ALPHABET_SIZE)]
    for first in range(ALPHABET_SIZE):
        pair_shift[first][pattern[0]] = pattern_length - 1
    for index in range(1, pattern_length - 1):
        pair_shift[pattern[index - 1]][pattern[index]] = pattern_length - 1 - index

    shifts = _good_suffix_shifts(pattern)
    start = 0
    while start <= text_length - pattern_length:
        mismatch = pattern_length - 1
        while mismatch >= 0 and pattern[mismatch] == text[start + mismatch]:
            mismatch -= 1
        if mismatch < 0:
            return start
        pair_first = text[start + pattern_length - 2]
        pair_second = text[start + pattern_length - 1]
        start += max(shifts[mismatch], pair_shift[pair_first][pair_second])
    return NOT_FOUND


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Return first offset, -1 when absent, or -2 for an invalid frame."""
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

    text_length, pattern_length = values[0], values[1]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or not MIN_PATTERN_LENGTH <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_length + pattern_length):
        return INVALID_RESULT
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(symbol < 0 or symbol >= ALPHABET_SIZE for symbol in text + pattern):
        return INVALID_RESULT
    return _search(text, pattern)
