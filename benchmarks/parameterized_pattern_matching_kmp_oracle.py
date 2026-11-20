"""Source-faithful modified-KMP oracle for parameterized string matching."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 64
MAX_PATTERN = 16
MAX_ALPHABET = 16
MAX_VALID_INPUT_LENGTH = 3 + MAX_TEXT + MAX_PATTERN
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_TEXT + 1)
WORKSPACE_BYTES = 4096


def _previous_positions(pattern: Sequence[int]) -> list[int]:
    last = [-1] * MAX_ALPHABET
    previous: list[int] = []
    for index, symbol in enumerate(pattern):
        previous.append(last[symbol])
        last[symbol] = index
    return previous


def _pattern_compare(pattern: Sequence[int], previous: Sequence[int],
                     current: int, prefix_position: int) -> bool:
    """AFM's mapped-match comparison during KMP prefix construction.

    If the prior occurrence of pattern[current] falls before the candidate
    prefix, pattern[prefix_position] must be new there. Otherwise the two
    symbols must have the same predecessor distance.
    """
    earlier = previous[current]
    if earlier < 0:
        return previous[prefix_position] < 0
    distance = current - earlier
    if distance > prefix_position:
        return previous[prefix_position] < 0
    return pattern[prefix_position] == pattern[prefix_position - distance]


def _search(text: Sequence[int], pattern: Sequence[int]) -> list[int]:
    m = len(pattern)
    previous = _previous_positions(pattern)

    # Build the parameterized border/failure table using AFM's pattern-pair
    # Compare predicate, rather than predecessor-code equality.
    failure = [0] * m
    for current in range(1, m):
        matched = failure[current - 1]
        while (matched > 0
               and not _pattern_compare(pattern, previous, current, matched)):
            matched = failure[matched - 1]
        if _pattern_compare(pattern, previous, current, matched):
            matched += 1
        failure[current] = matched

    last_text = [-1] * MAX_ALPHABET
    matches: list[int] = []
    matched = 0
    for text_index, symbol in enumerate(text):
        while True:
            pattern_previous = previous[matched]
            if pattern_previous < 0:
                candidate_start = text_index - matched
                equal = last_text[symbol] < candidate_start
            else:
                distance = matched - pattern_previous
                equal = text[text_index - distance] == symbol
            if equal:
                matched += 1
                if matched == m:
                    matches.append(text_index + 1 - m)
                    matched = failure[m - 1]
                break
            if matched == 0:
                break
            matched = failure[matched - 1]
        last_text[symbol] = text_index
    return matches


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    text_length, pattern_length, alphabet_size = values[:3]
    if (not 0 <= text_length <= MAX_TEXT
            or not 1 <= pattern_length <= MAX_PATTERN
            or not 1 <= alphabet_size <= MAX_ALPHABET
            or len(values) != 3 + text_length + pattern_length):
        return -1, b""
    text = values[3:3 + text_length]
    pattern = values[3 + text_length:]
    if any(not 0 <= symbol < alphabet_size for symbol in (*text, *pattern)):
        return -1, b""

    matches = _search(text, pattern) if pattern_length <= text_length else []
    payload = b"".join(struct.pack("<q", value)
                       for value in (len(matches), *matches))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
