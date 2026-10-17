"""Independent oracle for the pinned 16-word Salsa core variant."""

from __future__ import annotations

import struct
from collections.abc import Sequence

I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
WORD_COUNT = 16
MAX_VALID_INPUT_LENGTH = WORD_COUNT
MAX_PARSEABLE_INPUT_LENGTH = WORD_COUNT + 1
MAX_OUTPUT_BYTES = WORD_COUNT * 4
MASK32 = (1 << 32) - 1
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2

COLUMN_ROUNDS = ((0, 4, 8, 12), (5, 9, 13, 1), (10, 14, 2, 6), (15, 3, 7, 11))
ROW_ROUNDS = ((0, 1, 2, 3), (5, 6, 7, 4), (10, 11, 8, 9), (15, 12, 13, 14))


def _rotate_left(value: int, amount: int) -> int:
    return ((value << amount) | (value >> (32 - amount))) & MASK32


def _quarter_round(state: list[int], indices: tuple[int, int, int, int]) -> None:
    first, second, third, fourth = indices
    state[second] ^= _rotate_left((state[first] + state[fourth]) & MASK32, 7)
    state[third] ^= _rotate_left((state[second] + state[first]) & MASK32, 9)
    state[fourth] ^= _rotate_left((state[third] + state[second]) & MASK32, 13)
    state[first] ^= _rotate_left((state[fourth] + state[third]) & MASK32, 18)


def _salsa_core(words: Sequence[int]) -> bytes:
    original = [word & MASK32 for word in words]
    state = original.copy()
    for _ in range(10):
        for indices in COLUMN_ROUNDS:
            _quarter_round(state, indices)
        for indices in ROW_ROUNDS:
            _quarter_round(state, indices)
    result = [(state[index] + original[index]) & MASK32 for index in range(WORD_COUNT)]
    return struct.pack("<16I", *result)


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return 16 little-endian words or the bounded ABI sentinel."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values)
        or len(values) != MAX_VALID_INPUT_LENGTH
    ):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""

    output = _salsa_core(values)
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output
