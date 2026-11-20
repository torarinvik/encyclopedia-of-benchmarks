"""Primary perfect-factorization reference for Galil–Seiferas search."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 128
MIN_PATTERN_LENGTH = 1
MAX_PATTERN_LENGTH = 32
ALPHABET_SIZE = 16
MAX_VALID_INPUT_LENGTH = 162
MAX_PARSEABLE_INPUT_LENGTH = 162
INVALID_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
K = 4


def _factorize(pattern: Sequence[int]) -> tuple[int, int, int]:
    """Find the perfect factorization (s, p1, q1), using constant state."""
    m = len(pattern)
    s, p1, q1 = 0, 1, 0
    while True:  # newP1
        while s + p1 + q1 < m and pattern[s + q1] == pattern[s + p1 + q1]:
            q1 += 1
        if p1 + q1 >= K * p1:
            p2, q2 = q1, 0
            while True:  # newP2
                while (p2 + q2 < K * p2 and s + p2 + q2 < m
                       and pattern[s + q2] == pattern[s + p2 + q2]):
                    q2 += 1
                if p2 + q2 == K * p2:
                    while True:  # parse
                        while (s + p1 + q1 < m
                               and pattern[s + q1] == pattern[s + p1 + q1]):
                            q1 += 1
                        while p1 + q1 >= K * p1:
                            s += p1
                            q1 -= p1
                        if s + p1 + q1 == m:
                            return s, p1, q1
                        p1 += q1 // K + 1
                        q1 = 0
                        if p1 >= p2:
                            break
                    break  # newP1
                if s + p2 + q2 == m:
                    return s, p1, q1
                if q2 == p1 + q1:
                    p2 += p1
                    q2 -= p1
                else:
                    p2 += q2 // K + 1
                    q2 = 0
        else:
            if s + p1 + q1 == m:
                return s, p1, q1
            p1 += q1 // K + 1
            q1 = 0


def _count_matches(text: Sequence[int], pattern: Sequence[int]) -> int:
    n, m = len(text), len(pattern)
    if m > n:
        return 0
    s, p1, q1 = _factorize(pattern)
    p, q, matches = 0, 0, 0
    while p <= n - m:
        while s + q < m and pattern[s + q] == text[p + s + q]:
            q += 1
        if q == m - s:
            i = 0
            while i < s and pattern[i] == text[p + i]:
                i += 1
            if i == s:
                matches += 1
        if q == p1 + q1:
            p += p1
            q -= p1
        else:
            p += q // K + 1
            q = 0
    return matches


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
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
    if any(symbol < 0 or symbol >= ALPHABET_SIZE for symbol in text + pattern):
        return INVALID_RESULT
    return _count_matches(text, pattern)
