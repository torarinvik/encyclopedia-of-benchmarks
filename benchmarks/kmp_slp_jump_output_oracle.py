"""Primary bounded Jump/Output KMP oracle for DOI 81."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_PATTERN = 6
MAX_VARIABLES = 12
MAX_FACTORS = 8
MAX_EXPANDED_LENGTH = 64
MAX_INPUT_LENGTH = 53
MAX_OUTPUT_BYTES = 520
MAX_WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 8 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    pattern_length = values[0]
    if not 1 <= pattern_length <= MAX_PATTERN or len(values) < 3 + pattern_length:
        return None
    pattern = tuple(values[1:1 + pattern_length])
    if any(symbol < 0 or symbol > 3 for symbol in pattern):
        return None
    cursor = 1 + pattern_length
    variable_count = values[cursor]
    cursor += 1
    if not 1 <= variable_count <= MAX_VARIABLES or cursor + 3 * variable_count + 1 > len(values):
        return None
    definitions: list[tuple[int, int, int]] = []
    lengths: list[int] = []
    for variable in range(variable_count):
        kind, first, second = values[cursor:cursor + 3]
        cursor += 3
        if kind == 0:
            if not 0 <= first <= 3 or second != 0:
                return None
            lengths.append(1)
        elif kind == 1:
            if not 0 <= first < variable or not 0 <= second < variable:
                return None
            expanded = lengths[first] + lengths[second]
            if expanded > MAX_EXPANDED_LENGTH:
                return None
            lengths.append(expanded)
        else:
            return None
        definitions.append((kind, first, second))
    factor_count = values[cursor]
    cursor += 1
    if not 1 <= factor_count <= MAX_FACTORS or cursor + factor_count != len(values):
        return None
    factors = tuple(values[cursor:])
    if any(not 0 <= factor < variable_count for factor in factors):
        return None
    text_length = sum(lengths[factor] for factor in factors)
    if text_length > MAX_EXPANDED_LENGTH:
        return None
    return pattern, definitions, lengths, factors, text_length


def _prefix_function(pattern: tuple[int, ...]) -> list[int]:
    failure = [0] * len(pattern)
    border = 0
    for index in range(1, len(pattern)):
        while border and pattern[index] != pattern[border]:
            border = failure[border - 1]
        if pattern[index] == pattern[border]:
            border += 1
        failure[index] = border
    return failure


def _jump_output(pattern: tuple[int, ...], definitions: list[tuple[int, int, int]],
                 lengths: list[int], factors: tuple[int, ...]) -> list[int]:
    failure = _prefix_function(pattern)
    state_count = len(pattern)
    jumps = [[0] * state_count for _ in definitions]
    outputs = [[0] * state_count for _ in definitions]
    for variable, (kind, first, second) in enumerate(definitions):
        for start_state in range(state_count):
            if kind == 0:
                state = start_state
                symbol = first
                while state and pattern[state] != symbol:
                    state = failure[state - 1]
                if pattern[state] == symbol:
                    state += 1
                if state == state_count:
                    outputs[variable][start_state] = 1  # zero-based end offset 0 in this terminal
                    state = failure[state_count - 1]  # continue to report overlapping matches
                jumps[variable][start_state] = state
            else:
                middle = jumps[first][start_state]
                jumps[variable][start_state] = jumps[second][middle]
                outputs[variable][start_state] = (
                    outputs[first][start_state]
                    | (outputs[second][middle] << lengths[first])
                )
    state = 0
    offset = 0
    end_offsets = 0
    for variable in factors:
        end_offsets |= outputs[variable][state] << offset
        state = jumps[variable][state]
        offset += lengths[variable]
    starts = []
    while end_offsets:
        lowest = end_offsets & -end_offsets
        end_offset = lowest.bit_length() - 1
        starts.append(end_offset + 1 - state_count)
        end_offsets ^= lowest
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
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    pattern, definitions, lengths, factors, _ = parsed
    words = _jump_output(pattern, definitions, lengths, factors)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
