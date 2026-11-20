"""Alpha Skip Search using fixed-alphabet factor buckets."""

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


def _factor_length(pattern_length: int) -> int:
    length = 1
    while length + 1 <= pattern_length and 4 ** (length + 1) <= pattern_length:
        length += 1
    return length


def _factor_codes(symbols: list[int], factor_length: int) -> list[int]:
    if len(symbols) < factor_length:
        return []
    power = 4 ** (factor_length - 1)
    code = 0
    for symbol in symbols[:factor_length]:
        code = 4 * code + symbol
    codes = [code]
    for start in range(1, len(symbols) - factor_length + 1):
        code = (code - symbols[start - 1] * power) * 4 + symbols[start + factor_length - 1]
        codes.append(code)
    return codes


def _alpha_skip_matches(text: list[int], pattern: list[int]) -> list[int]:
    n = len(text)
    m = len(pattern)
    if n < m:
        return []
    factor_length = _factor_length(m)
    shift = m - factor_length + 1
    bucket_count = 4 ** factor_length
    buckets: list[list[int]] = [[] for _ in range(bucket_count)]
    for position, code in enumerate(_factor_codes(pattern, factor_length)):
        buckets[code].append(position)

    matches: list[int] = []
    text_codes = _factor_codes(text, factor_length)
    for sample_start in range(0, n - factor_length + 1, shift):
        for pattern_position in buckets[text_codes[sample_start]]:
            start = sample_start - pattern_position
            if 0 <= start <= n - m and text[start:start + m] == pattern:
                matches.append(start)
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
    return _pack(_alpha_skip_matches(text, pattern))
