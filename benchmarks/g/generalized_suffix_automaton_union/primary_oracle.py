"""Trie-built generalized suffix automaton, returning the union substring count."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_STRINGS = 2
MAX_STRINGS = 8
MAX_STRING_LENGTH = 8
MAX_TOTAL_LENGTH = 24
ALPHABET_SIZE = 4
MAX_VALID_INPUT_LENGTH = 33
MAX_PARSEABLE_INPUT_LENGTH = 34
WORKSPACE_BYTES = 4096


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
    if not values or not MIN_STRINGS <= values[0] <= MAX_STRINGS:
        return None
    strings = []
    cursor = 1
    total = 0
    for _ in range(values[0]):
        if cursor >= len(values):
            return None
        length = values[cursor]
        cursor += 1
        if not 0 <= length <= MAX_STRING_LENGTH or cursor + length > len(values):
            return None
        current = tuple(values[cursor:cursor + length])
        if any(not 0 <= symbol < ALPHABET_SIZE for symbol in current):
            return None
        strings.append(current)
        total += length
        cursor += length
    if cursor != len(values) or total > MAX_TOTAL_LENGTH:
        return None
    return strings


def union_substring_count(strings: list[tuple[int, ...]]) -> int:
    # Keep trie edges separate from automaton transitions. This makes the
    # breadth-first insertion order explicit while clones copy only SAM edges.
    trie_children: list[dict[int, int]] = [{}]
    for string in strings:
        node = 0
        for symbol in string:
            child = trie_children[node].get(symbol)
            if child is None:
                child = len(trie_children)
                trie_children[node][symbol] = child
                trie_children.append({})
            node = child

    states = len(trie_children)
    transitions: list[dict[int, int]] = [{} for _ in range(2 * states)]
    length = [0] * (2 * states)
    link = [-1] * (2 * states)
    queue = [0]
    used = states

    cursor = 0
    while cursor < len(queue):
        parent = queue[cursor]
        cursor += 1
        for symbol, current in trie_children[parent].items():
            length[current] = length[parent] + 1
            p = link[parent]
            while p != -1 and symbol not in transitions[p]:
                transitions[p][symbol] = current
                p = link[p]
            if p == -1:
                link[current] = 0
            else:
                q = transitions[p][symbol]
                if length[p] + 1 == length[q]:
                    link[current] = q
                else:
                    clone = used
                    used += 1
                    length[clone] = length[p] + 1
                    link[clone] = link[q]
                    transitions[clone] = {
                        edge: target for edge, target in transitions[q].items()
                        if length[target] > 0
                    }
                    while p != -1 and transitions[p].get(symbol) == q:
                        transitions[p][symbol] = clone
                        p = link[p]
                    link[q] = clone
                    link[current] = clone
            queue.extend(trie_children[current].values())

    return sum(length[state] - length[link[state]]
               for state in range(1, used))


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    strings = _decode(values, input_is_null, input_length)
    if strings is None:
        return -1
    return union_substring_count(strings)
