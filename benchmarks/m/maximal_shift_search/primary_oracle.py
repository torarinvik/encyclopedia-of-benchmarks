"""Maximal Shift pattern-order and adapted-shift reference."""

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


def _match_shift(pattern: list[int], order: list[tuple[int, int]],
                 prefix_length: int, shift: int) -> int:
    m = len(pattern)
    while shift < m:
        order_index = prefix_length - 1
        while order_index >= 0:
            pattern_index = order[order_index][0] - shift
            if pattern_index >= 0 and order[order_index][1] != pattern[pattern_index]:
                break
            order_index -= 1
        if order_index < 0:
            break
        shift += 1
    return shift


def _preprocess(pattern: list[int]):
    m = len(pattern)
    leading_shift = [0] * m
    for index in range(m):
        previous = index - 1
        while previous >= 0 and pattern[previous] != pattern[index]:
            previous -= 1
        leading_shift[index] = index - previous

    order = sorted(((index, pattern[index]) for index in range(m)),
                   key=lambda item: (-leading_shift[item[0]], -item[0]))
    order.append((m, -1))

    quick_shift = [m + 1] * 4
    for index, symbol in enumerate(pattern):
        quick_shift[symbol] = m - index

    adapted_shift = [0] * (m + 1)
    shift = 1
    for prefix_length in range(1, m + 1):
        shift = _match_shift(pattern, order, prefix_length, shift)
        adapted_shift[prefix_length] = shift
    adapted_shift[0] = 1
    for prefix_length in range(m + 1):
        shift = adapted_shift[prefix_length]
        while shift < m:
            pattern_index = order[prefix_length][0] - shift
            if (pattern_index < 0
                    or order[prefix_length][1] != pattern[pattern_index]):
                break
            shift += 1
            shift = _match_shift(pattern, order, prefix_length, shift)
        adapted_shift[prefix_length] = shift
    return order, quick_shift, adapted_shift


def _search(text: list[int], pattern: list[int]) -> list[int]:
    n, m = len(text), len(pattern)
    if n < m:
        return []
    order, quick_shift, adapted_shift = _preprocess(pattern)
    matches: list[int] = []
    start = 0
    while start <= n - m:
        compared = 0
        while (compared < m
               and order[compared][1] == text[start + order[compared][0]]):
            compared += 1
        if compared == m:
            matches.append(start)
        lookahead = start + m
        if lookahead >= n:
            break
        start += max(adapted_shift[compared], quick_shift[text[lookahead]])
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
    return _pack(_search(text, pattern))
