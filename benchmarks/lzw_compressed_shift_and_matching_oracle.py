"""Primary phrase-summary oracle for Shift-And over LZW code streams."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ALPHABET = 16
MAX_PATTERN = 32
MAX_CODES = 32
MAX_DICTIONARY = MAX_ALPHABET + MAX_CODES - 1
MAX_EXPANDED_LENGTH = MAX_CODES * (MAX_CODES + 1) // 2
MAX_INPUT_LENGTH = 3 + MAX_PATTERN + MAX_CODES
MAX_OUTPUT_BYTES = 8 * (1 + MAX_EXPANDED_LENGTH)
MAX_WORKSPACE_BYTES = 16384


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    alphabet_size, pattern_length, code_count = values[:3]
    if not 1 <= alphabet_size <= MAX_ALPHABET or not 1 <= pattern_length <= MAX_PATTERN:
        return None
    if not 0 <= code_count <= MAX_CODES or len(values) != 3 + pattern_length + code_count:
        return None
    pattern = tuple(values[3:3 + pattern_length])
    if any(not 0 <= symbol < alphabet_size for symbol in pattern):
        return None
    codes = tuple(values[3 + pattern_length:])
    if codes and not 0 <= codes[0] < alphabet_size:
        return None
    if any(code < 0 for code in codes):
        return None
    return alphabet_size, pattern, codes


def _phrase_summary(parent: int, symbol: int, parent_length: list[int],
                    first_symbol: list[int], match_mask: list[int],
                    cross_mask: list[int], in_match: list[bool],
                    previous_match: list[int], symbol_masks: list[int],
                    pattern_length: int, top_bit: int) -> int:
    node = len(parent_length)
    length = parent_length[parent] + 1
    matched = ((match_mask[parent] << 1) | 1) & symbol_masks[symbol]
    crossing = cross_mask[parent]
    if length < pattern_length and matched & top_bit:
        # Bit s-1 represents a prior Shift-And state of length s=m-length.
        crossing |= 1 << (pattern_length - length - 1)
    is_match = length >= pattern_length and bool(matched & top_bit)
    previous = parent if in_match[parent] else previous_match[parent]
    parent_length.append(length)
    first_symbol.append(first_symbol[parent])
    match_mask.append(matched)
    cross_mask.append(crossing)
    in_match.append(is_match)
    previous_match.append(previous)
    return node


def _shift_and_lzw(alphabet_size: int, pattern: tuple[int, ...],
                   codes: tuple[int, ...]) -> list[int] | None:
    m = len(pattern)
    top_bit = 1 << (m - 1)
    symbol_masks = [0] * alphabet_size
    for position, symbol in enumerate(pattern):
        symbol_masks[symbol] |= 1 << position

    parent_length = [0] * alphabet_size
    first_symbol = list(range(alphabet_size))
    match_mask = [0] * alphabet_size
    cross_mask = [0] * alphabet_size
    in_match = [False] * alphabet_size
    previous_match = [-1] * alphabet_size
    for symbol in range(alphabet_size):
        # A one-symbol phrase can align with any pattern position when it is
        # composed with the incoming Shift-And state.
        match_mask[symbol] = symbol_masks[symbol]
        if m > 1 and match_mask[symbol] & top_bit:
            cross_mask[symbol] = 1 << (m - 2)
        if m == 1:
            in_match[symbol] = bool(match_mask[symbol] & top_bit)
    parent_length = [1] * alphabet_size
    state = 0
    text_offset = 0
    starts: list[int] = []
    previous_code = -1

    for code in codes:
        next_code = len(parent_length)
        if previous_code < 0:
            if code >= alphabet_size:
                return None
            current_code = code
        else:
            if code > next_code:
                return None
            if code == next_code:
                appended_symbol = first_symbol[previous_code]
                current_code = _phrase_summary(
                    previous_code, appended_symbol, parent_length, first_symbol,
                    match_mask, cross_mask, in_match, previous_match, symbol_masks,
                    m, top_bit,
                )
            else:
                current_code = code
                appended_symbol = first_symbol[current_code]
                new_code = _phrase_summary(
                    previous_code, appended_symbol, parent_length, first_symbol,
                    match_mask, cross_mask, in_match, previous_match, symbol_masks,
                    m, top_bit,
                )

        phrase = current_code
        crossing_states = state & cross_mask[phrase]
        while crossing_states:
            highest = crossing_states.bit_length() - 1
            matched_prefix = highest + 1
            starts.append(text_offset - matched_prefix)
            crossing_states ^= 1 << highest

        internal_nodes: list[int] = []
        node = phrase if in_match[phrase] else previous_match[phrase]
        while node >= 0:
            internal_nodes.append(node)
            node = previous_match[node]
        for node in reversed(internal_nodes):
            starts.append(text_offset + parent_length[node] - m)

        length = parent_length[phrase]
        shifted = 0 if length >= m else state << length
        fresh_starts = (1 << min(length, m)) - 1
        state = (shifted | fresh_starts) & match_mask[phrase]
        text_offset += length
        previous_code = current_code
        if len(parent_length) > MAX_DICTIONARY:
            return None

    return [len(starts), *starts]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    alphabet_size, pattern, codes = parsed
    words = _shift_and_lzw(alphabet_size, pattern, codes)
    if words is None:
        return -1, b""
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
