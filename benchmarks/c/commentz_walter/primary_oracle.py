"""Bounded Commentz-Walter algorithm B reference implementation."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_PATTERNS = 6
MAX_PATTERN_LENGTH = 8
MAX_TOTAL_PATTERN_LENGTH = 32
MAX_TEXT_LENGTH = 64
ALPHABET_MAX = 4
MAX_VALID_INPUT_LENGTH = 2 + MAX_PATTERNS + MAX_TOTAL_PATTERN_LENGTH + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_PATTERNS * MAX_TEXT_LENGTH


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    pattern_count, text_length = values[:2]
    if (not 1 <= pattern_count <= MAX_PATTERNS
            or not 0 <= text_length <= MAX_TEXT_LENGTH
            or len(values) < 2 + pattern_count):
        return None
    lengths = list(values[2:2 + pattern_count])
    if any(not 1 <= size <= MAX_PATTERN_LENGTH for size in lengths):
        return None
    total = sum(lengths)
    if total > MAX_TOTAL_PATTERN_LENGTH or len(values) != 2 + pattern_count + total + text_length:
        return None
    at = 2 + pattern_count
    patterns: list[tuple[int, ...]] = []
    for size in lengths:
        pattern = tuple(values[at:at + size])
        if any(not 1 <= symbol <= ALPHABET_MAX for symbol in pattern):
            return None
        patterns.append(pattern)
        at += size
    if len(set(patterns)) != len(patterns):
        return None
    text = tuple(values[at:])
    if len(text) != text_length or any(not 1 <= symbol <= ALPHABET_MAX for symbol in text):
        return None
    return patterns, text


def _is_suffix(path: tuple[int, ...], candidate: tuple[int, ...]) -> bool:
    return len(path) < len(candidate) and candidate[-len(path):] == path


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the total number of pattern/start matches, including overlaps."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    patterns, text = parsed
    shortest = min(map(len, patterns))

    # Build a trie of reversed patterns. Paths store the traversed symbols so
    # the two safe-shift sets can be computed directly from their definitions.
    children: list[dict[int, int]] = [{}]
    parents = [-1]
    labels = [0]
    paths: list[tuple[int, ...]] = [()]
    terminal = [False]
    for pattern in patterns:
        node = 0
        for symbol in reversed(pattern):
            child = children[node].get(symbol)
            if child is None:
                child = len(children)
                children[node][symbol] = child
                children.append({})
                parents.append(node)
                labels.append(symbol)
                paths.append(paths[node] + (symbol,))
                terminal.append(False)
            node = child
        terminal[node] = True

    depth = [len(path) for path in paths]
    node_count = len(children)
    shift1 = [shortest] * node_count
    shift1[0] = 1
    shift2 = [shortest] * node_count
    bad_character = [shortest + 1] * (ALPHABET_MAX + 1)
    for node in range(1, node_count):
        bad_character[labels[node]] = min(bad_character[labels[node]], depth[node])
        for suffix_node in range(1, node_count):
            if _is_suffix(paths[node], paths[suffix_node]):
                shift1[node] = min(shift1[node], depth[suffix_node] - depth[node])
                if terminal[suffix_node]:
                    shift2[node] = min(shift2[node], depth[suffix_node] - depth[node])
        shift2[node] = min(shift2[node], shift2[parents[node]])

    total_matches = 0
    position = shortest - 1
    while position < len(text):
        node = 0
        index = position
        while index >= 0:
            child = children[node].get(text[index])
            if child is None:
                break
            node = child
            index -= 1
            if terminal[node]:
                total_matches += 1
        mismatched = text[index] if index >= 0 else 0
        char_shift = bad_character[mismatched] if mismatched else shortest + 1
        delta = min(shift2[node], max(shift1[node], char_shift - depth[node] - 1))
        position += delta
    return total_matches
