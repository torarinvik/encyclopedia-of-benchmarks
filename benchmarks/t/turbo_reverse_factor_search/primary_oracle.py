"""Sparse weighted suffix-automaton implementation of Turbo Reverse Factor."""
from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 4096
MAX_PATTERN_LENGTH = 128
MAX_SYMBOL = 3
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (1 << 49) - 1
WORKSPACE_BYTES = 28672


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


def _build_weighted_suffix_automaton(pattern: list[int]):
    # State 0 is the automaton root; state 1 is its artificial suffix sentinel.
    transitions: list[dict[int, int]] = [{}, {}]
    displacement: list[dict[int, int]] = [{}, {}]
    suffix_link = [1, -1]
    max_length = [0, 0]
    position = [0, 0]
    terminal = [False, False]
    root = 0
    last = root

    for symbol in reversed(pattern):
        current = len(transitions)
        transitions.append({})
        displacement.append({})
        suffix_link.append(-1)
        max_length.append(max_length[last] + 1)
        position.append(position[last] + 1)
        terminal.append(False)

        state = last
        while state != root and symbol not in transitions[state]:
            transitions[state][symbol] = current
            displacement[state][symbol] = position[current] - position[state] - 1
            state = suffix_link[state]

        target = transitions[state].get(symbol)
        if target is None:
            transitions[root][symbol] = current
            displacement[root][symbol] = position[current] - position[root] - 1
            suffix_link[current] = root
        elif max_length[state] + 1 == max_length[target]:
            suffix_link[current] = target
        else:
            clone = len(transitions)
            transitions.append(transitions[target].copy())
            displacement.append(displacement[target].copy())
            suffix_link.append(suffix_link[target])
            max_length.append(max_length[state] + 1)
            position.append(position[target])
            terminal.append(terminal[target])
            suffix_link[target] = clone
            suffix_link[current] = clone

            while state != 1:
                old_target = transitions[state].get(symbol)
                if old_target is None or max_length[old_target] < max_length[clone]:
                    break
                displacement[state][symbol] = position[old_target] - position[state] - 1
                transitions[state][symbol] = clone
                state = suffix_link[state]
        last = current

    state = last
    terminal[state] = True
    while state != root:
        state = suffix_link[state]
        terminal[state] = True
    return transitions, displacement, suffix_link, max_length, position, terminal


def _morris_pratt_next(pattern: list[int]) -> list[int]:
    table = [-1] + [0] * len(pattern)
    i = 0
    border = -1
    while i < len(pattern):
        while border >= 0 and pattern[i] != pattern[border]:
            border = table[border]
        i += 1
        border += 1
        table[i] = border
    return table


def _turbo_reverse_factor_offsets(text: list[int], pattern: list[int]) -> list[int]:
    n, m = len(text), len(pattern)
    if n < m:
        return []
    (transitions, displacement, _suffix_link, _max_length,
     _position, terminal) = _build_weighted_suffix_automaton(pattern)
    mp_next = _morris_pratt_next(pattern)
    pattern_period = m - mp_next[m]

    offsets: list[int] = []
    start = 0
    preceding_shift = m
    while start <= n - m:
        index = m - 1
        state = 0
        boundary = m - 1 - preceding_shift
        prefix_length = m - preceding_shift
        period_of_prefix = (
            prefix_length - mp_next[prefix_length]
            if preceding_shift != m else 0
        )
        shift = m
        total_displacement = 0

        while index > boundary:
            symbol = text[start + index]
            target = transitions[state].get(symbol)
            if target is None:
                break
            total_displacement += displacement[state][symbol]
            state = target
            if terminal[state]:
                shift = index
            index -= 1

        if index <= boundary:
            if total_displacement == 0:
                offsets.append(start)
                shift = pattern_period
            else:
                half = (boundary + 1) // 2
                if period_of_prefix <= half:
                    boundary -= period_of_prefix
                    while index > boundary:
                        symbol = text[start + index]
                        target = transitions[state].get(symbol)
                        if target is None:
                            break
                        total_displacement += displacement[state][symbol]
                        state = target
                        if terminal[state]:
                            shift = index
                        index -= 1
                    if index <= boundary:
                        shift = total_displacement
                else:
                    boundary = boundary - half - 1
                    while index > boundary:
                        symbol = text[start + index]
                        target = transitions[state].get(symbol)
                        if target is None:
                            break
                        total_displacement += displacement[state][symbol]
                        state = target
                        if terminal[state]:
                            shift = index
                        index -= 1

        if shift <= 0:  # The construction guarantees a positive shift.
            return []
        start += shift
        preceding_shift = shift
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
    return _pack(_turbo_reverse_factor_offsets(text, pattern))
