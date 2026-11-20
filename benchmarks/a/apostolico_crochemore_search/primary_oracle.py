"""Apostolico-Crochemore all-occurrences search with KMP-next shifts."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 4096
MAX_PATTERN_LENGTH = 128
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
COUNT_SHIFT = 36
SUM_SHIFT = 12
WORKSPACE_BYTES = 8192


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 1 <= pattern_length <= MAX_PATTERN_LENGTH:
        return None
    if len(values) != 2 + text_length + pattern_length:
        return None
    text = tuple(values[2:2 + text_length])
    pattern = tuple(values[2 + text_length:])
    if any(not 0 <= value <= 3 for value in text + pattern):
        return None
    return text, pattern


def _kmp_next(pattern: tuple[int, ...]) -> list[int]:
    length = len(pattern)
    pattern_with_sentinel = pattern + (4,)
    next_shift = [0] * (length + 1)
    position = 0
    border = -1
    next_shift[0] = -1
    while position < length:
        while (border > -1
               and pattern_with_sentinel[position] != pattern_with_sentinel[border]):
            border = next_shift[border]
        position += 1
        border += 1
        if pattern_with_sentinel[position] != pattern_with_sentinel[border]:
            next_shift[position] = border
        else:
            next_shift[position] = next_shift[border]
    return next_shift


def find_occurrences(text: tuple[int, ...], pattern: tuple[int, ...]) -> list[int]:
    text_length = len(text)
    pattern_length = len(pattern)
    if pattern_length > text_length:
        return []

    ell = 1
    while ell < pattern_length and pattern[ell] == pattern[0]:
        ell += 1
    if ell == pattern_length:
        ell = 0

    next_shift = _kmp_next(pattern)
    i = ell
    j = 0
    k = 0
    matches: list[int] = []
    while j <= text_length - pattern_length:
        while i < pattern_length and pattern[i] == text[j + i]:
            i += 1
        if i >= pattern_length:
            while k < ell and pattern[k] == text[j + k]:
                k += 1
            if k >= ell:
                matches.append(j)

        j += i - next_shift[i]
        if i == ell:
            k = max(0, k - 1)
        elif next_shift[i] <= ell:
            k = max(0, next_shift[i])
            i = ell
        else:
            k = ell
            i = next_shift[i]
    return matches


def _pack_matches(offsets: list[int]) -> int:
    count = len(offsets)
    offset_sum = sum(offsets)
    offset_xor = 0
    for offset in offsets:
        offset_xor ^= offset
    return (count << COUNT_SHIFT) | (offset_sum << SUM_SHIFT) | offset_xor


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    return _pack_matches(find_occurrences(text, pattern))
