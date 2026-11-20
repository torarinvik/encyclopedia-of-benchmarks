"""Reverse Factor search using a suffix automaton for the reversed pattern."""

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


def _build_suffix_automaton(reversed_pattern: list[int]):
    capacity = 2 * len(reversed_pattern) + 1
    transitions = [[-1] * 4 for _ in range(capacity)]
    suffix_link = [-1] * capacity
    max_length = [0] * capacity
    state_count = 1
    last = 0
    for symbol in reversed_pattern:
        current = state_count
        state_count += 1
        max_length[current] = max_length[last] + 1
        predecessor = last
        while predecessor >= 0 and transitions[predecessor][symbol] < 0:
            transitions[predecessor][symbol] = current
            predecessor = suffix_link[predecessor]
        if predecessor < 0:
            suffix_link[current] = 0
        else:
            target = transitions[predecessor][symbol]
            if max_length[predecessor] + 1 == max_length[target]:
                suffix_link[current] = target
            else:
                clone = state_count
                state_count += 1
                transitions[clone] = transitions[target].copy()
                max_length[clone] = max_length[predecessor] + 1
                suffix_link[clone] = suffix_link[target]
                while (predecessor >= 0
                       and transitions[predecessor][symbol] == target):
                    transitions[predecessor][symbol] = clone
                    predecessor = suffix_link[predecessor]
                suffix_link[target] = clone
                suffix_link[current] = clone
        last = current

    terminal = [False] * state_count
    state = last
    while state >= 0:
        terminal[state] = True
        state = suffix_link[state]
    return transitions[:state_count], terminal


def _reverse_factor_matches(text: list[int], pattern: list[int]) -> list[int]:
    n, m = len(text), len(pattern)
    if n < m:
        return []
    transitions, terminal = _build_suffix_automaton(pattern[::-1])
    matches: list[int] = []
    period = m
    start = 0
    while start <= n - m:
        index = m - 1
        state = 0
        shift = m
        while start + index >= 0:
            target = transitions[state][text[start + index]]
            if target < 0:
                break
            state = target
            if terminal[state]:
                period = shift
                shift = index
            index -= 1
        if index < 0:
            matches.append(start)
            shift = period
        start += shift
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
    return _pack(_reverse_factor_matches(text, pattern))
