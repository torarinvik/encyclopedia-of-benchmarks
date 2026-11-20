"""Primary sparse-automaton reference for Simon string matching."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 256
MIN_PATTERN_LENGTH = 1
MAX_PATTERN_LENGTH = 16
ALPHABET_SIZE = 16
MAX_VALID_INPUT_LENGTH = 274
MAX_PARSEABLE_INPUT_LENGTH = 274
INVALID_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Count overlapping hits while traversing Simon's sparse prefix DFA."""
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

    # back[p] stores only significant backward edges from prefix state p.
    # Forward edges to the next prefix are recovered directly from pattern.
    back: list[list[int]] = [[] for _ in range(max(0, m - 1))]
    longest_border_state = -1
    for i in range(1, m):
        k = longest_border_state
        prior = tuple(back[k]) if k >= 0 else ()
        longest_border_state = -1
        if pattern[i] == pattern[k + 1]:
            longest_border_state = k + 1
        else:
            back[i - 1].insert(0, k + 1)
        for target in prior:
            if pattern[i] == pattern[target]:
                longest_border_state = target
            else:
                back[i - 1].insert(0, target)

    state = -1
    matches = 0
    for symbol in text:
        if state < m - 1 and pattern[state + 1] == symbol:
            state += 1
        elif state >= 0:
            next_state = -1
            for target in back[state]:
                if pattern[target] == symbol:
                    next_state = target
                    break
            state = next_state
        else:
            state = -1
        if state >= m - 1:
            matches += 1
            state = longest_border_state
    return matches
