"""Pair-distinguishability reference for bounded DFA minimization."""

from collections.abc import Sequence

MAX_STATES = 8
MAX_ALPHABET = 3
MAX_VALID_INPUT_LENGTH = 4 + MAX_STATES * MAX_ALPHABET
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None):
    if values is None or not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, alphabet, start, accepting = values[:4]
    if not 1 <= n <= MAX_STATES or not 1 <= alphabet <= MAX_ALPHABET or not 0 <= start < n:
        return None
    if not 0 <= accepting < (1 << n) or len(values) != 4 + n * alphabet:
        return None
    transitions = [list(values[4 + s * alphabet:4 + (s + 1) * alphabet]) for s in range(n)]
    if any(not 0 <= target < n for row in transitions for target in row):
        return None
    return n, alphabet, accepting, transitions


def expected(values: Sequence[int] | None, input_is_null: bool = False,
             input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return -1
    if input_length is not None:
        if not isinstance(values, (list, tuple)) or type(input_length) is not int or input_length != len(values):
            return -1
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, alphabet, accepting, transitions = parsed
    distinguishable = [[False] * n for _ in range(n)]
    for left in range(n):
        for right in range(left + 1, n):
            distinguishable[left][right] = bool((accepting >> left) & 1) != bool((accepting >> right) & 1)

    rounds = 0
    while True:
        newly_marked: list[tuple[int, int]] = []
        for left in range(n):
            for right in range(left + 1, n):
                if distinguishable[left][right]:
                    continue
                for symbol in range(alphabet):
                    a, b = transitions[left][symbol], transitions[right][symbol]
                    lo, hi = (a, b) if a < b else (b, a)
                    if lo != hi and distinguishable[lo][hi]:
                        newly_marked.append((left, right))
                        break
        if not newly_marked:
            break
        for left, right in newly_marked:
            distinguishable[left][right] = True
        rounds += 1

    labels = [-1] * n
    class_count = 0
    for state in range(n):
        for prior in range(state):
            if not distinguishable[prior][state]:
                labels[state] = labels[prior]
                break
        if labels[state] < 0:
            labels[state] = class_count
            class_count += 1
    packed_labels = sum(label << (3 * state) for state, label in enumerate(labels))
    return (class_count << 28) | (rounds << 24) | packed_labels


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    del capacity, output_is_null
    return expected(values, input_is_null=input_is_null, input_length=input_length)
