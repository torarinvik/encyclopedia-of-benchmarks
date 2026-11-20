"""Direct all-alignment verifier for the bounded exact-search workload."""
from __future__ import annotations

from primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN_LENGTH,
    MAX_RESULT,
    MAX_SYMBOL,
    MAX_TEXT_LENGTH,
)


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, m = values[:2]
    if (not 0 <= n <= MAX_TEXT_LENGTH or not 1 <= m <= MAX_PATTERN_LENGTH
            or len(values) != 2 + n + m):
        return None
    text = list(values[2:2 + n])
    pattern = list(values[2 + n:])
    if any(not 0 <= symbol <= MAX_SYMBOL for symbol in text + pattern):
        return None
    return text, pattern


def _direct_offsets(text: list[int], pattern: list[int]) -> list[int]:
    width = len(pattern)
    return [start for start in range(len(text) - width + 1)
            if text[start:start + width] == pattern]


def _pack(offsets: list[int]) -> int:
    count = len(offsets)
    offset_sum = sum(offsets)
    offset_xor = 0
    for offset in offsets:
        offset_xor ^= offset
    result = (count << 36) | (offset_sum << 12) | offset_xor
    return result if result <= MAX_RESULT else -1


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    return _pack(_direct_offsets(text, pattern))
