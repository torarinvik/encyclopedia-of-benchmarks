"""Bounded DC3 (difference-cover modulo 3) suffix-array oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 16
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2
MAX_OUTPUT_BYTES = 8 * MAX_TEXT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _symbol(symbols: Sequence[int], position: int) -> int:
    return symbols[position] if position < len(symbols) else 0


def _rank(ranks: Sequence[int], position: int) -> int:
    return ranks[position] if position < len(ranks) else -1


def _triple_compare(symbols: Sequence[int], left: int, right: int) -> int:
    for offset in range(3):
        a = _symbol(symbols, left + offset)
        b = _symbol(symbols, right + offset)
        if a != b:
            return -1 if a < b else 1
    return 0


def _pair_compare(symbols: Sequence[int], ranks: Sequence[int], left: int, right: int) -> int:
    a = (_symbol(symbols, left), _rank(ranks, left + 1))
    b = (_symbol(symbols, right), _rank(ranks, right + 1))
    return (a > b) - (a < b)


def _mixed_compare(symbols: Sequence[int], ranks: Sequence[int], zero_pos: int,
                   sample_pos: int) -> int:
    if sample_pos % 3 == 1:
        a = (_symbol(symbols, zero_pos), _rank(ranks, zero_pos + 1))
        b = (_symbol(symbols, sample_pos), _rank(ranks, sample_pos + 1))
    else:
        a = (_symbol(symbols, zero_pos), _symbol(symbols, zero_pos + 1),
             _rank(ranks, zero_pos + 2))
        b = (_symbol(symbols, sample_pos), _symbol(symbols, sample_pos + 1),
             _rank(ranks, sample_pos + 2))
    return (a > b) - (a < b)


def _dc3(symbols: Sequence[int]) -> list[int]:
    """Sort suffix starts using the R0/R12 recursion and merge comparisons."""
    n = len(symbols)
    if n == 0:
        return []
    if n <= 3:
        return sorted(range(n), key=lambda start: tuple(symbols[start:]))

    sample = [position for position in range(n) if position % 3 != 0]
    for index in range(1, len(sample)):
        key = sample[index]
        position = index
        while position > 0 and _triple_compare(symbols, key, sample[position - 1]) < 0:
            sample[position] = sample[position - 1]
            position -= 1
        sample[position] = key

    triple_rank = [0] * n
    next_rank = 0
    previous = None
    for position in sample:
        if previous is None or _triple_compare(symbols, previous, position) != 0:
            next_rank += 1
        triple_rank[position] = next_rank
        previous = position

    group_one_count = sum(1 for position in range(1, n, 3))
    reduced = [triple_rank[position] for position in range(1, n, 3)]
    reduced.append(0)  # Separate the two residue runs with the low sentinel.
    reduced.extend(triple_rank[position] for position in range(2, n, 3))
    reduced_order = _dc3(reduced)
    sample_order = []
    for position in reduced_order:
        if position == group_one_count:
            continue
        source_position = (1 + 3 * position if position < group_one_count
                           else 2 + 3 * (position - group_one_count - 1))
        sample_order.append(source_position)

    ranks = [-1] * n
    for rank, position in enumerate(sample_order):
        ranks[position] = rank

    zero_positions = [position for position in range(0, n, 3)]
    for index in range(1, len(zero_positions)):
        key = zero_positions[index]
        position = index
        while position > 0 and _pair_compare(
                symbols, ranks, key, zero_positions[position - 1]) < 0:
            zero_positions[position] = zero_positions[position - 1]
            position -= 1
        zero_positions[position] = key

    result: list[int] = []
    zero_index = sample_index = 0
    while zero_index < len(zero_positions) and sample_index < len(sample_order):
        zero_pos = zero_positions[zero_index]
        sample_pos = sample_order[sample_index]
        if _mixed_compare(symbols, ranks, zero_pos, sample_pos) < 0:
            result.append(zero_pos)
            zero_index += 1
        else:
            result.append(sample_pos)
            sample_index += 1
    result.extend(zero_positions[zero_index:])
    result.extend(sample_order[sample_index:])
    return result


def _decode(values: Sequence[int] | None) -> list[int] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_TEXT_LENGTH or len(values) != count + 1:
        return None
    if any(not 0 <= symbol <= 255 for symbol in values[1:]):
        return None
    # DC3 reserves zero for the smaller-than-alphabet padding symbol.
    return [symbol + 1 for symbol in values[1:]]


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
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    symbols = _decode(values)
    if symbols is None:
        return INVALID_RESULT, b""
    payload = struct.pack("<" + "q" * len(symbols), *_dc3(symbols))
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
