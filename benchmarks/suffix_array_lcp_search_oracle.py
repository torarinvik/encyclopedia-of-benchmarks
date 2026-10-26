"""Primary oracle for the bounded LCP-enhanced suffix-array search."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_PATTERN = 16
MAX_INPUT = 50
MAX_OUTPUT = 264


def _parse(values, input_is_null, input_length):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) < n + 2:
        return None
    text = tuple(values[1:1 + n])
    m_at = 1 + n
    m = values[m_at]
    if not 1 <= m <= MAX_PATTERN or len(values) != m_at + 1 + m:
        return None
    pattern = tuple(values[m_at + 1:])
    if any(not 0 <= symbol <= 127 for symbol in (*text, *pattern)):
        return None
    return text, pattern


def _index(text):
    suffixes = sorted(range(len(text)), key=lambda start: text[start:])
    adjacent = [0] * max(0, len(text) - 1)
    for i in range(len(adjacent)):
        a, b = suffixes[i], suffixes[i + 1]
        length = 0
        while a + length < len(text) and b + length < len(text) and text[a + length] == text[b + length]:
            length += 1
        adjacent[i] = length
    left_q = [[0] * len(text) for _ in text]
    right_q = [[0] * len(text) for _ in text]
    stack = [(0, len(text) - 1)]
    while stack:
        lo, hi = stack.pop()
        if hi - lo < 2:
            continue
        mid = (lo + hi + 1) // 2
        left_q[lo][hi] = min(adjacent[lo:mid])
        right_q[lo][hi] = min(adjacent[mid:hi])
        if hi - mid >= 2:
            stack.append((mid, hi))
        if mid - lo >= 2:
            stack.append((lo, mid))
    return suffixes, left_q, right_q


def _compare(text, start, pattern, offset, prefix_equal):
    matched = offset
    while matched < len(pattern) and start + matched < len(text) and text[start + matched] == pattern[matched]:
        matched += 1
    if matched == len(pattern):
        if prefix_equal or start + matched == len(text):
            return 0, matched
        return 1, matched
    if start + matched == len(text):
        return -1, matched
    return (-1 if text[start + matched] < pattern[matched] else 1), matched


def _bound(text, pattern, suffixes, left_q, right_q, prefix_equal):
    n = len(text)
    cmp_first, l = _compare(text, suffixes[0], pattern, 0, prefix_equal)
    cmp_last, r = _compare(text, suffixes[-1], pattern, 0, prefix_equal)
    if cmp_first > 0 or (cmp_first == 0 and not prefix_equal):
        return 0
    if cmp_last < 0 or (cmp_last == 0 and prefix_equal):
        return n
    lo, hi = 0, n - 1
    # The endpoints bracket the target. A span of one is the insertion point.
    while hi - lo > 1:
        mid = (lo + hi + 1) // 2
        if l == r:
            cmp_mid, matched = _compare(text, suffixes[mid], pattern, l, prefix_equal)
            if cmp_mid > 0 or (cmp_mid == 0 and not prefix_equal):
                hi, r = mid, matched
            else:
                lo, l = mid, matched
        elif l > r:
            q = left_q[lo][hi]
            if l < q:
                lo = mid
            elif l > q:
                hi, r = mid, q
            else:
                cmp_mid, matched = _compare(text, suffixes[mid], pattern, l, prefix_equal)
                if cmp_mid > 0 or (cmp_mid == 0 and not prefix_equal):
                    hi, r = mid, matched
                else:
                    lo, l = mid, matched
        else:
            q = right_q[lo][hi]
            if r < q:
                hi = mid
            elif r > q:
                lo, l = mid, q
            else:
                cmp_mid, matched = _compare(text, suffixes[mid], pattern, r, prefix_equal)
                if cmp_mid > 0 or (cmp_mid == 0 and not prefix_equal):
                    hi, r = mid, matched
                else:
                    lo, l = mid, matched
    return hi


def _solve(parsed):
    text, pattern = parsed
    suffixes, left_q, right_q = _index(text)
    low = _bound(text, pattern, suffixes, left_q, right_q, False)
    high = _bound(text, pattern, suffixes, left_q, right_q, True)
    return [high - low, *suffixes[low:high]]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    result = _solve(parsed)
    payload = b"".join(value.to_bytes(8, "little", signed=True) for value in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
