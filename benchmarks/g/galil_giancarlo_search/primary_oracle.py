"""Galil–Giancarlo ordered search with its heavy-prefix transition."""
from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 4096
MAX_PATTERN_LENGTH = 128
MAX_SYMBOL = 3
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (1 << 49) - 1
WORKSPACE_BYTES = 49152


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


def _preprocess(pattern: list[int]):
    """Build Colussi's ordered-comparison and shift tables."""
    m = len(pattern)
    extended = [*pattern, MAX_SYMBOL + 1]
    hmax = [0] * (m + 2)
    kmin = [0] * (m + 1)
    rmin = [0] * (m + 1)
    order = [0] * (m + 1)
    next_position = [0] * (m + 1)
    shift = [0] * (m + 1)

    i = k = 1
    while True:
        while extended[i] == extended[i - k]:
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

    split = -1
    tail = m
    for i in range(m):
        if kmin[i] == 0:
            tail -= 1
            order[tail] = i
        else:
            split += 1
            order[split] = i
    nd = split

    for i in range(nd + 1):
        shift[i] = kmin[order[i]]
    for i in range(nd + 1, m):
        shift[i] = rmin[order[i]]
    shift[m] = rmin[0]

    nohole_prefix = [0] * (m + 1)
    count = 0
    for i in range(m):
        nohole_prefix[i] = count
        if kmin[i] > 0:
            count += 1
    for i in range(nd + 1):
        next_position[i] = nohole_prefix[order[i] - kmin[order[i]]]
    for i in range(nd + 1, m):
        next_position[i] = nohole_prefix[m - rmin[order[i]]]
    next_position[m] = nohole_prefix[m - rmin[order[m - 1]]]
    return order, next_position, shift, nd


def _summarize(offsets: list[int]) -> int:
    count = len(offsets)
    offset_sum = sum(offsets)
    offset_xor = 0
    for offset in offsets:
        offset_xor ^= offset
    result = (count << 36) | (offset_sum << 12) | offset_xor
    return result if result <= MAX_RESULT else -1


def _galil_giancarlo_offsets(text: list[int], pattern: list[int]) -> list[int]:
    n, m = len(text), len(pattern)
    first = pattern[0]
    ell = 0
    while ell + 1 < m and pattern[ell + 1] == first:
        ell += 1

    offsets: list[int] = []
    if ell == m - 1:
        run = 0
        for position, symbol in enumerate(text):
            run = run + 1 if symbol == first else 0
            if run >= m:
                offsets.append(position - m + 1)
        return offsets

    order, next_position, shift, nd = _preprocess(pattern)
    if n < m:
        return offsets
    i = j = 0
    last = -1
    heavy = False
    while j <= n - m:
        if heavy and i == 0:
            k = last - j + 1
            while j + k < n and pattern[0] == text[j + k]:
                k += 1
            if (k <= ell or j + k >= n
                    or pattern[ell + 1] != text[j + k]):
                i = 0
                j += k + 1
                last = j - 1
            else:
                i = 1
                last = j + k
                j = last - (ell + 1)
        else:
            while (i < m and last < j + order[i]
                   and pattern[order[i]] == text[j + order[i]]):
                i += 1
            if i >= m or last >= j + order[i]:
                offsets.append(j)
                i = m
            if i > nd:
                last = j + m - 1
            j += shift[i]
            i = next_position[i]
        heavy = j <= last
    return offsets


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    return _summarize(_galil_giancarlo_offsets(text, pattern))
