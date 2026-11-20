"""Skip Search reference using character-position buckets."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 4096
MAX_PATTERN_LENGTH = 128
MAX_SYMBOL = 3
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (1 << 49) - 1
WORKSPACE_BYTES = 65536


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
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or not 1 <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_length + pattern_length):
        return None
    text = list(values[2:2 + text_length])
    pattern = list(values[2 + text_length:])
    if any(not 0 <= symbol <= MAX_SYMBOL for symbol in text + pattern):
        return None
    return text, pattern


def _skip_search_matches(text: list[int], pattern: list[int]) -> list[int]:
    n, m = len(text), len(pattern)
    if n < m:
        return []

    buckets: list[list[int]] = [[] for _ in range(MAX_SYMBOL + 1)]
    for position, symbol in enumerate(pattern):
        buckets[symbol].append(position)

    matches: list[int] = []
    sample = m - 1
    while sample < n:
        for pattern_position in buckets[text[sample]]:
            start = sample - pattern_position
            if start < 0 or start > n - m:
                continue
            matched = 0
            while matched < m and text[start + matched] == pattern[matched]:
                matched += 1
            if matched == m:
                matches.append(start)
        sample += m
    return matches


def _pack(matches: list[int]) -> int:
    count = len(matches)
    offset_sum = sum(matches)
    offset_xor = 0
    for offset in matches:
        offset_xor ^= offset
    return (count << 36) | (offset_sum << 12) | offset_xor


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    return _pack(_skip_search_matches(text, pattern))
