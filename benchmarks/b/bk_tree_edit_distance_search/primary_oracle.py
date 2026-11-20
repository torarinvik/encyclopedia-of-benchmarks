"""Distance-labelled BK-tree build and radius-search reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_WORDS = 16
MAX_QUERIES = 8
MAX_WORD_LENGTH = 10
MAX_RADIUS = 3
MAX_VALID_INPUT_LENGTH = 3 + MAX_WORDS + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1


def _word_is_valid(word: int) -> bool:
    if type(word) is not int or word < 0 or word >= (1 << 44):
        return False
    length = (word >> 40) & 0xF
    if length > MAX_WORD_LENGTH:
        return False
    for position in range(MAX_WORD_LENGTH):
        symbol = (word >> (4 * position)) & 0xF
        if position < length:
            if not 1 <= symbol <= 15:
                return False
        elif symbol != 0:
            return False
    return True


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    dictionary_count, query_count, radius = values[:3]
    if (not 0 <= dictionary_count <= MAX_WORDS
            or not 0 <= query_count <= MAX_QUERIES
            or not 0 <= radius <= MAX_RADIUS
            or len(values) != 3 + dictionary_count + query_count):
        return None
    dictionary = values[3:3 + dictionary_count]
    queries = values[3 + dictionary_count:]
    if any(not _word_is_valid(word) for word in dictionary + queries):
        return None
    if len(set(dictionary)) != dictionary_count:
        return None
    return dictionary, queries, radius


def levenshtein(left: int, right: int) -> int:
    left_length = (left >> 40) & 0xF
    right_length = (right >> 40) & 0xF
    previous = list(range(right_length + 1))
    current = [0] * (right_length + 1)
    for i in range(1, left_length + 1):
        current[0] = i
        a_symbol = (left >> (4 * (i - 1))) & 0xF
        for j in range(1, right_length + 1):
            b_symbol = (right >> (4 * (j - 1))) & 0xF
            substitution = previous[j - 1] + (a_symbol != b_symbol)
            current[j] = min(previous[j] + 1, current[j - 1] + 1,
                             substitution)
        previous, current = current, previous
    return previous[right_length]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    dictionary, queries, radius = parsed
    children = [[-1] * (MAX_WORD_LENGTH + 1) for _ in dictionary]
    if dictionary:
        for new_index in range(1, len(dictionary)):
            node_index = 0
            while True:
                edge = levenshtein(dictionary[new_index], dictionary[node_index])
                child_index = children[node_index][edge]
                if child_index == -1:
                    children[node_index][edge] = new_index
                    break
                node_index = child_index

    result = 0
    for query_index, query in enumerate(queries):
        match_count = 0
        index_sum = 0
        if dictionary:
            pending = [0]
            while pending:
                node_index = pending.pop()
                distance = levenshtein(query, dictionary[node_index])
                if distance <= radius:
                    match_count += 1
                    index_sum += node_index
                low = max(0, distance - radius)
                high = min(MAX_WORD_LENGTH, distance + radius)
                for edge in range(low, high + 1):
                    child_index = children[node_index][edge]
                    if child_index != -1:
                        pending.append(child_index)
        result += (query_index + 1) * (17 * match_count + index_sum)
    return result
