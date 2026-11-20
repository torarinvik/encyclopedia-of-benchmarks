"""Online maximal-suffix reference for ordered-alphabet string search."""

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


def _advance_maximal_suffix(segment: list[int], state: list[int]) -> None:
    """Update the maximal-suffix decomposition state in place."""
    left, right, offset, period = state
    while right + offset < len(segment):
        a = segment[left + offset]
        b = segment[right + offset]
        if a == b:
            if offset == period:
                right += period
                offset = 1
            else:
                offset += 1
        elif a > b:
            right += offset
            offset = 1
            period = right - left
        else:
            left = right
            right += 1
            offset = 1
            period = 1
    state[:] = [left, right, offset, period]


def _prefix_repeats(segment: list[int], shift: int, last_index: int) -> bool:
    if shift + last_index >= len(segment):
        return False
    for index in range(last_index + 1):
        if segment[index] != segment[shift + index]:
            return False
    return True


def _ordered_alphabet_matches(text: list[int], pattern: list[int]) -> list[int]:
    n, m = len(text), len(pattern)
    if n < m:
        return []

    alignment = 0
    matched = 0
    suffix_state = [-1, 0, 1, 1]
    matches: list[int] = []
    while alignment <= n - m:
        while (alignment + matched < n and matched < m
               and pattern[matched] == text[alignment + matched]):
            matched += 1

        if matched == 0:
            alignment += 1
            suffix_state[:] = [-1, 0, 1, 1]
            continue

        if matched == m:
            matches.append(alignment)
            if alignment == n - m:
                break

        segment = text[alignment:alignment + matched + 1]
        _advance_maximal_suffix(segment, suffix_state)
        left, right, _, period = suffix_state
        can_reuse_period = (
            left < 0 or (left < period and _prefix_repeats(segment, period, left))
        )
        if can_reuse_period:
            alignment += period
            matched = max(0, matched - period)
            if right - left > period:
                suffix_state[1] = right - period
            else:
                suffix_state[:] = [-1, 0, 1, 1]
        else:
            conservative_shift = min(matched - left - 1, right + 1)
            alignment += max(left + 1, conservative_shift) + 1
            matched = 0
            suffix_state[:] = [-1, 0, 1, 1]
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
    return _pack(_ordered_alphabet_matches(text, pattern))
