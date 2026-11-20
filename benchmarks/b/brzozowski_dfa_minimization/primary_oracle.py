"""Bounded reverse/subset/reverse/subset DFA-minimization reference."""

from collections.abc import Sequence

MAX_STATES = 3
MAX_ALPHABET = 2
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_STATES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_MINIMAL_STATES = 1 << (1 << MAX_STATES)
WORKSPACE_BYTES = 8192


def _parse(values: Sequence[int] | None) -> tuple[int, int, int, list[tuple[int, int]]] | None:
    if values is None or not isinstance(values, (list, tuple)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, start, accepting = values[:3]
    if not 1 <= n <= MAX_STATES or not 0 <= start < n or not 0 <= accepting < (1 << n):
        return None
    if len(values) != 3 + MAX_ALPHABET * n:
        return None
    transitions: list[tuple[int, int]] = []
    cursor = 3
    for _ in range(n):
        pair = (values[cursor], values[cursor + 1])
        if any(not 0 <= target < n for target in pair):
            return None
        transitions.append(pair)
        cursor += 2
    return n, start, accepting, transitions


def _determinize_reverse(state_count: int, initial_subset: int, final_state_mask: int,
                         transitions: list[tuple[int, int]]) -> tuple[list[int], list[tuple[int, int]], list[bool]]:
    subsets = [initial_subset]
    indexes = {initial_subset: 0}
    deterministic: list[tuple[int, int]] = []
    accepting: list[bool] = []
    cursor = 0
    while cursor < len(subsets):
        subset = subsets[cursor]
        accepting.append(bool(subset & final_state_mask))
        outgoing: list[int] = []
        for symbol in range(MAX_ALPHABET):
            predecessor = 0
            for state in range(state_count):
                if subset & (1 << transitions[state][symbol]):
                    predecessor |= 1 << state
            if predecessor not in indexes:
                indexes[predecessor] = len(subsets)
                subsets.append(predecessor)
            outgoing.append(indexes[predecessor])
        deterministic.append((outgoing[0], outgoing[1]))
        cursor += 1
    return subsets, deterministic, accepting


def expected(values: Sequence[int] | None) -> int:
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, start, accepting_mask, transitions = parsed
    _, first_transitions, first_accepting = _determinize_reverse(
        n, accepting_mask, 1 << start, transitions
    )
    first_accepting_mask = sum((1 << state) for state, flag in enumerate(first_accepting) if flag)
    reversed_first = _determinize_reverse(
        len(first_transitions), first_accepting_mask, 1, first_transitions
    )
    return len(reversed_first[0])
