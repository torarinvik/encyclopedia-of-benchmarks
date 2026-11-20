"""KmpSkip Search with symbol buckets and MP/KMP shift reconciliation."""

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
    n, m = values[:2]
    if (not 0 <= n <= MAX_TEXT_LENGTH or not 1 <= m <= MAX_PATTERN_LENGTH
            or len(values) != 2 + n + m):
        return None
    text = list(values[2:2 + n])
    pattern = list(values[2 + n:])
    if any(not 0 <= symbol <= MAX_SYMBOL for symbol in text + pattern):
        return None
    return text, pattern


def _prefix_tables(pattern: list[int]) -> tuple[list[int], list[int]]:
    m = len(pattern)
    mp_next = [-1] * (m + 1)
    i = 0
    border = -1
    while i < m:
        while border >= 0 and pattern[i] != pattern[border]:
            border = mp_next[border]
        i += 1
        border += 1
        mp_next[i] = border

    kmp_next = [-1] * (m + 1)
    i = 0
    border = -1
    while i < m:
        while border >= 0 and pattern[i] != pattern[border]:
            border = kmp_next[border]
        i += 1
        border += 1
        if i < m and pattern[i] == pattern[border]:
            kmp_next[i] = kmp_next[border]
        else:
            kmp_next[i] = border
    return mp_next, kmp_next


def _kmp_skip_matches(text: list[int], pattern: list[int]) -> list[int]:
    n, m = len(text), len(pattern)
    if n < m:
        return []

    mp_next, kmp_next = _prefix_tables(pattern)
    last = [-1] * 4
    previous = [-1] * m
    for position, symbol in enumerate(pattern):
        previous[position] = last[symbol]
        last[symbol] = position

    def advance_sample(sample: int) -> tuple[int, int] | None:
        while True:
            sample += m
            if sample >= n:
                return None
            position = last[text[sample]]
            if position >= 0:
                return sample, position

    state = advance_sample(-1)
    if state is None:
        return []
    j, i = state
    start = j - i
    wall = 0
    period = m - kmp_next[m]
    matches: list[int] = []

    while start <= n - m:
        if start > wall:
            wall = start
        k = wall - start
        while k < m and pattern[k] == text[start + k]:
            k += 1
        wall = start + k
        if k == m:
            matches.append(start)
            i -= period
        else:
            i = previous[i]

        if i < 0:
            state = advance_sample(j)
            if state is None:
                break
            j, i = state

        kmp_start = start + k - kmp_next[k]
        k = kmp_next[k]
        start = j - i
        while start < kmp_start or (kmp_start < start and start < wall):
            if start < kmp_start:
                i = previous[i]
                if i < 0:
                    state = advance_sample(j)
                    if state is None:
                        return matches
                    j, i = state
                start = j - i
            else:
                kmp_start += k - mp_next[k]
                k = mp_next[k]
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
    return _pack(_kmp_skip_matches(text, pattern))
