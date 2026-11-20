"""Sparse-map suffix-automaton oracle for Forward DAWG Matching."""
from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 4096
MAX_PATTERN_LENGTH = 128
MAX_SYMBOL = 3
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (1 << 49) - 1
WORKSPACE_BYTES = 16384


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
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


def _build_suffix_automaton(pattern: list[int]):
    transitions: list[dict[int, int]] = [{}]
    suffix_link = [-1]
    max_length = [0]
    last = 0

    for symbol in pattern:
        current = len(transitions)
        transitions.append({})
        suffix_link.append(0)
        max_length.append(max_length[last] + 1)
        state = last
        while state != -1 and symbol not in transitions[state]:
            transitions[state][symbol] = current
            state = suffix_link[state]
        if state == -1:
            suffix_link[current] = 0
        else:
            target = transitions[state][symbol]
            if max_length[state] + 1 == max_length[target]:
                suffix_link[current] = target
            else:
                clone = len(transitions)
                transitions.append(transitions[target].copy())
                suffix_link.append(suffix_link[target])
                max_length.append(max_length[state] + 1)
                while state != -1 and transitions[state].get(symbol) == target:
                    transitions[state][symbol] = clone
                    state = suffix_link[state]
                suffix_link[target] = clone
                suffix_link[current] = clone
        last = current
    return transitions, suffix_link, max_length


def _forward_dawg_offsets(text: list[int], pattern: list[int]) -> list[int]:
    transitions, suffix_link, max_length = _build_suffix_automaton(pattern)
    state = matched_length = 0
    offsets: list[int] = []
    for position, symbol in enumerate(text):
        target = transitions[state].get(symbol)
        if target is not None:
            matched_length += 1
            state = target
        else:
            while state != 0 and symbol not in transitions[state]:
                state = suffix_link[state]
            target = transitions[state].get(symbol)
            if target is not None:
                matched_length = max_length[state] + 1
                state = target
            else:
                matched_length = 0
                state = 0
        if matched_length == len(pattern):
            offsets.append(position - len(pattern) + 1)
    return offsets


def _pack(offsets: list[int]) -> int:
    count = len(offsets)
    offset_sum = sum(offsets)
    offset_xor = 0
    for offset in offsets:
        offset_xor ^= offset
    result = (count << 36) | (offset_sum << 12) | offset_xor
    return result if result <= MAX_RESULT else -1


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    return _pack(_forward_dawg_offsets(text, pattern))
