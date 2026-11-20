"""Reverse Colussi exact matching with its pattern-specific comparison order."""

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


def _tables(pattern: list[int]):
    m = len(pattern)
    hmin = [m - 1] * (m + 1)
    for shift in range(1, m + 1):
        last_mismatch = shift - 1
        for pos in range(shift, m):
            if pattern[pos] != pattern[pos - shift]:
                last_mismatch = pos
        hmin[shift] = last_mismatch

    kmin = [0] * m
    for shift in range(m, 0, -1):
        end = hmin[shift]
        if end != m - 1:
            kmin[end] = shift

    rmin = [m] * m
    next_boundary = m
    for end in range(m - 1, -1, -1):
        if hmin[end + 1] == end:
            next_boundary = end + 1
        rmin[end] = next_boundary

    order = [0] * m
    good_suffix = [0] * (m + 1)
    order[0] = m - 1
    cursor = 0
    for shift in range(1, m + 1):
        end = hmin[shift]
        if end != m - 1 and kmin[end] == shift:
            cursor += 1
            order[cursor] = end
            good_suffix[cursor] = shift
    cursor = m - 1
    for end in range(m - 2, -1, -1):
        if kmin[end] == 0:
            order[cursor] = end
            good_suffix[cursor] = rmin[end]
            cursor -= 1
    good_suffix[m] = rmin[0]

    bad_character = [[m] * (m + 1) for _ in range(4)]
    for symbol in range(4):
        for prior_shift in range(1, m + 1):
            boundary = m - prior_shift - 1
            for shift in range(1, m + 1):
                if shift < m and pattern[m - shift - 1] != symbol:
                    continue
                if shift <= boundary:
                    if pattern[m - shift - prior_shift - 1] != pattern[boundary]:
                        continue
                bad_character[symbol][prior_shift] = shift
                break
    return order, good_suffix, bad_character


def _reverse_colussi_matches(text: list[int], pattern: list[int]) -> list[int]:
    n, m = len(text), len(pattern)
    if n < m:
        return []
    order, good_suffix, bad_character = _tables(pattern)
    matches: list[int] = []
    start = 0
    shift_state = m
    last_start = n - m
    while start <= last_start:
        while (start <= last_start
               and pattern[m - 1] != text[start + m - 1]):
            shift_state = bad_character[text[start + m - 1]][shift_state]
            start += shift_state
        if start > last_start:
            break
        index = 1
        while index < m and pattern[order[index]] == text[start + order[index]]:
            index += 1
        if index == m:
            matches.append(start)
        shift_state = good_suffix[index]
        start += shift_state
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
    return _pack(_reverse_colussi_matches(text, pattern))
