"""Colussi's two-phase, hole-aware exact matcher."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 4096
MAX_PATTERN_LENGTH = 128
MAX_SYMBOL = 3
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (1 << 49) - 1
WORKSPACE_BYTES = 32768


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


def _preprocess(pattern: list[int]):
    m = len(pattern)
    x = [*pattern, MAX_SYMBOL + 1]
    hmax = [0] * (m + 2)
    kmin = [0] * (m + 1)
    rmin = [0] * (m + 1)
    h = [0] * (m + 1)
    next_position = [0] * (m + 1)
    shift = [0] * (m + 1)

    i = k = 1
    while True:
        while x[i] == x[i - k]:
            i += 1
        hmax[k] = i
        q = k + 1
        while hmax[q - k] + k < i:
            hmax[q] = hmax[q - k] + k
            q += 1
        k = q
        if k == i + 1:
            i = k
        if k > m:
            break

    for i in range(m, 0, -1):
        if hmax[i] < m:
            kmin[hmax[i]] = i

    r = m
    for i in range(m - 1, -1, -1):
        if hmax[i + 1] == m:
            r = i + 1
        if kmin[i] == 0:
            rmin[i] = r

    s = -1
    r = m
    for i in range(m):
        if kmin[i] == 0:
            r -= 1
            h[r] = i
        else:
            s += 1
            h[s] = i
    nd = s

    for i in range(nd + 1):
        shift[i] = kmin[h[i]]
    for i in range(nd + 1, m):
        shift[i] = rmin[h[i]]
    shift[m] = rmin[0]

    nhd0 = [0] * (m + 1)
    s = 0
    for i in range(m):
        nhd0[i] = s
        if kmin[i] > 0:
            s += 1

    for i in range(nd + 1):
        next_position[i] = nhd0[h[i] - kmin[h[i]]]
    for i in range(nd + 1, m):
        next_position[i] = nhd0[m - rmin[h[i]]]
    next_position[m] = nhd0[m - rmin[h[m - 1]]]
    return h, next_position, shift, nd


def _colussi_matches(text: list[int], pattern: list[int]) -> list[int]:
    n = len(text)
    m = len(pattern)
    if n < m:
        return []
    h, next_position, shift, nd = _preprocess(pattern)
    i = j = 0
    last = -1
    matches = []
    while j <= n - m:
        while (i < m and last < j + h[i]
               and pattern[h[i]] == text[j + h[i]]):
            i += 1
        if i >= m or last >= j + h[i]:
            matches.append(j)
            i = m
        if i > nd:
            last = j + m - 1
        j += shift[i]
        i = next_position[i]
    return matches


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    matches = _colussi_matches(text, pattern)
    count = len(matches)
    offset_sum = sum(matches)
    offset_xor = 0
    for offset in matches:
        offset_xor ^= offset
    result = (count << 36) | (offset_sum << 12) | offset_xor
    return result if result <= MAX_RESULT else -1
